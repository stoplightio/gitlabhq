module Gitlab
  module Git
    module Conflict
      class File
        attr_reader :content, :their_path, :our_path, :our_mode, :repository, :commit_oid

        def initialize(repository, commit_oid, conflict, content)
          @repository = repository
          @commit_oid = commit_oid
          @their_path = conflict[:theirs][:path]
          @our_path = conflict[:ours][:path]
          @our_mode = conflict[:ours][:mode]
          @content = content
        end

        def lines
          return @lines if defined?(@lines)

          begin
            @type = 'text'
            @lines = Gitlab::Git::Conflict::Parser.parse(content,
                                                         our_path: our_path,
                                                         their_path: their_path)
          rescue Gitlab::Git::Conflict::Parser::ParserError
            @type = 'text-editor'
            @lines = nil
          end
        end

        def type
          lines unless @type

          @type.inquiry
        end

        def our_blob
          # REFACTOR NOTE: the source of `commit_oid` used to be
          # `merge_request.diff_refs.head_sha`. Instead of passing this value
          # around the new lib structure, I decided to use `@commit_oid` which is
          # equivalent to `merge_request.source_branch_head.raw.rugged_commit.oid`.
          # That is what `merge_request.diff_refs.head_sha` is equivalent to when
          # `merge_request` is not persisted (see `MergeRequest#diff_head_commit`).
          # I think using the same oid is more consistent anyways, but if Conflicts
          # start breaking, the change described above is a good place to look at.
          @our_blob ||= repository.blob_at(@commit_oid, our_path)
        end

        def line_code(line)
          Gitlab::Git.diff_line_code(our_path, line[:line_new], line[:line_old])
        end

        def resolve_lines(resolution)
          section_id = nil

          lines.map do |line|
            unless line[:type]
              section_id = nil
              next line
            end

            section_id ||= line_code(line)

            case resolution[section_id]
            when 'head'
              next unless line[:type] == 'new'
            when 'origin'
              next unless line[:type] == 'old'
            else
              raise Gitlab::Git::Conflict::Resolver::ResolutionError, "Missing resolution for section ID: #{section_id}"
            end

            line
          end.compact
        end

        def resolve_content(resolution)
          if resolution == content
            raise Gitlab::Git::Conflict::Resolver::ResolutionError, "Resolved content has no changes for file #{our_path}"
          end

          resolution
        end
      end
    end
  end
end
