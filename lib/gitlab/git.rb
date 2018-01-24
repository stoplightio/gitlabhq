module Gitlab
  module Git
    BLANK_SHA = ('0' * 40).freeze
    TAG_REF_PREFIX = "refs/tags/".freeze
    BRANCH_REF_PREFIX = "refs/heads/".freeze

    CommandError = Class.new(StandardError)
    CommitError = Class.new(StandardError)

    class << self
      include Gitlab::EncodingHelper

      def ref_name(ref)
        encode_utf8(ref).sub(/\Arefs\/(tags|heads|remotes)\//, '')
      end

      def branch_name(ref)
        ref = ref.to_s
        if self.branch_ref?(ref)
          self.ref_name(ref)
        else
          nil
        end
      end

      def committer_hash(email:, name:)
        return if email.nil? || name.nil?

        {
          email: email,
          name: name,
          time: Time.now
        }
      end

      def tag_name(ref)
        ref = ref.to_s
        if self.tag_ref?(ref)
          self.ref_name(ref)
        else
          nil
        end
      end

      def tag_ref?(ref)
        ref.start_with?(TAG_REF_PREFIX)
      end

      def branch_ref?(ref)
        ref.start_with?(BRANCH_REF_PREFIX)
      end

      def blank_ref?(ref)
        ref == BLANK_SHA
      end

      def version
        Gitlab::VersionInfo.parse(Gitlab::Popen.popen(%W(#{Gitlab.config.git.bin_path} --version)).first)
      end

      def check_namespace!(*objects)
        expected_namespace = self.name + '::'
        objects.each do |object|
          unless object.class.name.start_with?(expected_namespace)
            raise ArgumentError, "expected object in #{expected_namespace}, got #{object}"
          end
        end
      end

      def diff_line_code(file_path, new_line_position, old_line_position)
        "#{Digest::SHA1.hexdigest(file_path)}_#{old_line_position}_#{new_line_position}"
      end

      def shas_eql?(sha1, sha2)
        return false if sha1.nil? || sha2.nil?
        return false unless sha1.class == sha2.class

        # If either of the shas is below the minimum length, we cannot be sure
        # that they actually refer to the same commit because of hash collision.
        length = [sha1.length, sha2.length].min
        return false if length < Gitlab::Git::Commit::MIN_SHA_LENGTH

        sha1[0, length] == sha2[0, length]
      end
    end
  end
end
