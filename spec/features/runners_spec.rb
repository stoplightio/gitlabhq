require 'spec_helper'

feature 'Runners' do
  given(:user) { create(:user) }

  background do
    sign_in(user)
  end

  context 'when user opens runners page' do
    given(:project) { create(:project) }

    background do
      project.add_master(user)
    end

    scenario 'user can see a button to install runners on kubernetes clusters' do
      visit project_runners_path(project)

      expect(page).to have_link('Install Runner on Kubernetes', href: project_clusters_path(project))
    end
  end

  context 'when a project has enabled shared_runners' do
    given(:project) { create(:project) }

    background do
      project.add_master(user)
    end

    context 'when a specific runner is activated on the project' do
      given(:specific_runner) { create(:ci_runner, :specific) }

      background do
        project.runners << specific_runner
      end

      scenario 'user sees the specific runner' do
        visit project_runners_path(project)

        within '.activated-specific-runners' do
          expect(page).to have_content(specific_runner.display_name)
        end

        click_on specific_runner.short_sha

        expect(page).to have_content(specific_runner.platform)
      end

      scenario 'user can pause and resume the specific runner' do
        visit project_runners_path(project)

        within '.activated-specific-runners' do
          expect(page).to have_content('Pause')
        end

        click_on 'Pause'

        within '.activated-specific-runners' do
          expect(page).to have_content('Resume')
        end

        click_on 'Resume'

        within '.activated-specific-runners' do
          expect(page).to have_content('Pause')
        end
      end

      scenario 'user removes an activated specific runner if this is last project for that runners' do
        visit project_runners_path(project)

        within '.activated-specific-runners' do
          click_on 'Remove Runner'
        end

        expect(page).not_to have_content(specific_runner.display_name)
      end

      scenario 'user edits the runner to be protected' do
        visit project_runners_path(project)

        within '.activated-specific-runners' do
          first('.edit-runner > a').click
        end

        expect(page.find_field('runner[access_level]')).not_to be_checked

        check 'runner_access_level'
        click_button 'Save changes'

        expect(page).to have_content 'Protected Yes'
      end

      context 'when a runner has a tag' do
        background do
          specific_runner.update(tag_list: ['tag'])
        end

        scenario 'user edits runner not to run untagged jobs' do
          visit project_runners_path(project)

          within '.activated-specific-runners' do
            first('.edit-runner > a').click
          end

          expect(page.find_field('runner[run_untagged]')).to be_checked

          uncheck 'runner_run_untagged'
          click_button 'Save changes'

          expect(page).to have_content 'Can run untagged jobs No'
        end
      end

      context 'when a shared runner is activated on the project' do
        given!(:shared_runner) { create(:ci_runner, :shared) }

        scenario 'user sees CI/CD setting page' do
          visit project_runners_path(project)

          expect(page.find('.available-shared-runners')).to have_content(shared_runner.display_name)
        end
      end
    end

    context 'when a specific runner exists in another project' do
      given(:another_project) { create(:project) }
      given(:specific_runner) { create(:ci_runner, :specific) }

      background do
        another_project.add_master(user)
        another_project.runners << specific_runner
      end

      scenario 'user enables and disables a specific runner' do
        visit project_runners_path(project)

        within '.available-specific-runners' do
          click_on 'Enable for this project'
        end

        expect(page.find('.activated-specific-runners')).to have_content(specific_runner.display_name)

        within '.activated-specific-runners' do
          click_on 'Disable for this project'
        end

        expect(page.find('.available-specific-runners')).to have_content(specific_runner.display_name)
      end
    end

    context 'when application settings have shared_runners_text' do
      given(:shared_runners_text) { 'custom **shared** runners description' }
      given(:shared_runners_html) { 'custom shared runners description' }

      background do
        stub_application_setting(shared_runners_text: shared_runners_text)
      end

      scenario 'user sees shared runners description' do
        visit project_runners_path(project)

        expect(page.find('.shared-runners-description')).to have_content(shared_runners_html)
      end
    end
  end

  context 'when a project has disabled shared_runners' do
    given(:project) { create(:project, shared_runners_enabled: false) }

    background do
      project.add_master(user)
    end

    scenario 'user enables shared runners' do
      visit project_runners_path(project)

      click_on 'Enable shared Runners'

      expect(page.find('.shared-runners-description')).to have_content('Disable shared Runners')
    end
  end

  context 'group runners in project settings' do
    background do
      project.add_master(user)
    end

    given(:group) { create :group }

    context 'as project and group master' do
      background do
        group.add_master(user)
      end

      context 'project with a group but no group runner' do
        given(:project) { create :project, group: group }

        scenario 'group runners are not available' do
          visit project_runners_path(project)

          expect(page).to have_content 'This group does not provide any group Runners yet'

          expect(page).to have_content 'Group masters can register group runners in the Group CI/CD settings'
          expect(page).not_to have_content 'Ask your group master to setup a group Runner'
        end
      end
    end

    context 'as project master' do
      context 'project without a group' do
        given(:project) { create :project }

        scenario 'group runners are not available' do
          visit project_runners_path(project)

          expect(page).to have_content 'This project does not belong to a group and can therefore not make use of group Runners.'
        end
      end

      context 'project with a group but no group runner' do
        given(:group) { create :group }
        given(:project) { create :project, group: group }

        scenario 'group runners are not available' do
          visit project_runners_path(project)

          expect(page).to have_content 'This group does not provide any group Runners yet.'

          expect(page).not_to have_content 'Group masters can register group runners in the Group CI/CD settings'
          expect(page).to have_content 'Ask your group master to setup a group Runner.'
        end
      end

      context 'project with a group and a group runner' do
        given(:group) { create :group }
        given(:project) { create :project, group: group }
        given!(:ci_runner) { create :ci_runner, groups: [group], description: 'group-runner' }

        scenario 'group runners are available' do
          visit project_runners_path(project)

          expect(page).to have_content 'Available group Runners : 1'
          expect(page).to have_content 'group-runner'
        end

        scenario 'group runners may be disabled for a project' do
          visit project_runners_path(project)

          click_on 'Disable group Runners'

          expect(page).to have_content 'Enable group Runners'
          expect(project.reload.group_runners_enabled).to be false

          click_on 'Enable group Runners'

          expect(page).to have_content 'Disable group Runners'
          expect(project.reload.group_runners_enabled).to be true
        end
      end
    end
  end

  context 'group runners in group settings' do
    given(:group) { create :group }
    background do
      group.add_master(user)
    end

    context 'group with no runners' do
      scenario 'there are no runners displayed' do
        visit group_settings_ci_cd_path(group)

        expect(page).to have_content 'This group does not provide any group Runners yet'
      end
    end

    context 'group with a runner' do
      let!(:runner) { create :ci_runner, groups: [group], description: 'group-runner' }

      scenario 'the runner is visible' do
        visit group_settings_ci_cd_path(group)

        expect(page).not_to have_content 'This group does not provide any group Runners yet'
        expect(page).to have_content 'Available group Runners : 1'
        expect(page).to have_content 'group-runner'
      end

      scenario 'user can pause and resume the group runner' do
        visit group_settings_ci_cd_path(group)

        expect(page).to have_content('Pause')
        expect(page).not_to have_content('Resume')

        click_on 'Pause'

        expect(page).not_to have_content('Pause')
        expect(page).to have_content('Resume')

        click_on 'Resume'

        expect(page).to have_content('Pause')
        expect(page).not_to have_content('Resume')
      end

      scenario 'user can view runner details' do
        visit group_settings_ci_cd_path(group)

        expect(page).to have_content(runner.display_name)

        click_on runner.short_sha

        expect(page).to have_content(runner.platform)
      end

      scenario 'user can remove a group runner' do
        visit group_settings_ci_cd_path(group)

        click_on 'Remove Runner'

        expect(page).not_to have_content(runner.display_name)
      end

      scenario 'user edits the runner to be protected' do
        visit group_settings_ci_cd_path(group)

        first('.edit-runner > a').click

        expect(page.find_field('runner[access_level]')).not_to be_checked

        check 'runner_access_level'
        click_button 'Save changes'

        expect(page).to have_content 'Protected Yes'
      end

      context 'when a runner has a tag' do
        background do
          runner.update(tag_list: ['tag'])
        end

        scenario 'user edits runner not to run untagged jobs' do
          visit group_settings_ci_cd_path(group)

          first('.edit-runner > a').click

          expect(page.find_field('runner[run_untagged]')).to be_checked

          uncheck 'runner_run_untagged'
          click_button 'Save changes'

          expect(page).to have_content 'Can run untagged jobs No'
        end
      end
    end
  end
end
