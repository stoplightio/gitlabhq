require 'stringio'

module Gitlab
  module GitalyClient
    class WikiService
      MAX_MSG_SIZE = 128.kilobytes.freeze

      def initialize(repository)
        @gitaly_repo = repository.gitaly_repository
        @repository = repository
      end

      def write_page(name, format, content, commit_details)
        request = Gitaly::WikiWritePageRequest.new(
          repository: @gitaly_repo,
          name: GitalyClient.encode(name),
          format: format.to_s,
          commit_details: gitaly_commit_details(commit_details)
        )

        strio = GitalyClient.binary_stringio(content)

        enum = Enumerator.new do |y|
          until strio.eof?
            request.content = strio.read(MAX_MSG_SIZE)

            y.yield request

            request = Gitaly::WikiWritePageRequest.new
          end
        end

        response = GitalyClient.call(@repository.storage, :wiki_service, :wiki_write_page, enum)
        if error = response.duplicate_error.presence
          raise Gitlab::Git::Wiki::DuplicatePageError, error
        end
      end

      def update_page(page_path, title, format, content, commit_details)
        request = Gitaly::WikiUpdatePageRequest.new(
          repository: @gitaly_repo,
          page_path: GitalyClient.encode(page_path),
          title: GitalyClient.encode(title),
          format: format.to_s,
          commit_details: gitaly_commit_details(commit_details)
        )

        strio = GitalyClient.binary_stringio(content)

        enum = Enumerator.new do |y|
          until strio.eof?
            request.content = strio.read(MAX_MSG_SIZE)

            y.yield request

            request = Gitaly::WikiUpdatePageRequest.new
          end
        end

        GitalyClient.call(@repository.storage, :wiki_service, :wiki_update_page, enum)
      end

      def delete_page(page_path, commit_details)
        request = Gitaly::WikiDeletePageRequest.new(
          repository: @gitaly_repo,
          page_path: GitalyClient.encode(page_path),
          commit_details: gitaly_commit_details(commit_details)
        )

        GitalyClient.call(@repository.storage, :wiki_service, :wiki_delete_page, request)
      end

      def find_page(title:, version: nil, dir: nil)
        request = Gitaly::WikiFindPageRequest.new(
          repository: @gitaly_repo,
          title: GitalyClient.encode(title),
          revision: GitalyClient.encode(version),
          directory: GitalyClient.encode(dir)
        )

        response = GitalyClient.call(@repository.storage, :wiki_service, :wiki_find_page, request)

        wiki_page_from_iterator(response)
      end

      def get_all_pages
        request = Gitaly::WikiGetAllPagesRequest.new(repository: @gitaly_repo)
        response = GitalyClient.call(@repository.storage, :wiki_service, :wiki_get_all_pages, request)
        pages = []

        loop do
          page, version = wiki_page_from_iterator(response) { |message| message.end_of_page }

          break unless page && version

          pages << [page, version]
        end

        pages
      end

      def find_file(name, revision)
        request = Gitaly::WikiFindFileRequest.new(
          repository: @gitaly_repo,
          name: GitalyClient.encode(name),
          revision: GitalyClient.encode(revision)
        )

        response = GitalyClient.call(@repository.storage, :wiki_service, :wiki_find_file, request)
        wiki_file = nil

        response.each do |message|
          next unless message.name.present?

          if wiki_file
            wiki_file.raw_data << message.raw_data
          else
            wiki_file = GitalyClient::WikiFile.new(message.to_h)
            # All gRPC strings in a response are frozen, so we get
            # an unfrozen version here so appending in the else clause below doesn't blow up.
            wiki_file.raw_data = wiki_file.raw_data.dup
          end
        end

        wiki_file
      end

      private

      # If a block is given and the yielded value is true, iteration will be
      # stopped early at that point; else the iterator is consumed entirely.
      # The iterator is traversed with `next` to allow resuming the iteration.
      def wiki_page_from_iterator(iterator)
        wiki_page = version = nil

        while message = iterator.next
          break if block_given? && yield(message)

          page = message.page
          next unless page

          if wiki_page
            wiki_page.raw_data << page.raw_data
          else
            wiki_page = GitalyClient::WikiPage.new(page.to_h)

            version = Gitlab::Git::WikiPageVersion.new(
              Gitlab::Git::Commit.decorate(@repository, page.version.commit),
              page.version.format
            )
          end
        end

        [wiki_page, version]
      rescue StopIteration
        [wiki_page, version]
      end

      def gitaly_commit_details(commit_details)
        Gitaly::WikiCommitDetails.new(
          name: GitalyClient.encode(commit_details.name),
          email: GitalyClient.encode(commit_details.email),
          message: GitalyClient.encode(commit_details.message)
        )
      end
    end
  end
end
