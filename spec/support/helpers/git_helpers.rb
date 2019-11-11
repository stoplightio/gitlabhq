# frozen_string_literal: true

module GitHelpers
  def rugged_repo(repository)
    path = File.join(TestEnv.repos_path, repository.disk_path + '.git')

    Rugged::Repository.new(path)
  end

  def project_hook_exists?(project)
    Gitlab::GitalyClient::StorageSettings.allow_disk_access do
      project_path = project.repository.raw_repository.path

      File.exist?(File.join(project_path, 'hooks', 'post-receive'))
    end
  end
end
