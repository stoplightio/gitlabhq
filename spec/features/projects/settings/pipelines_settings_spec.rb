require 'spec_helper'

feature "Pipelines settings" do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:role) { :developer }

  background do
    sign_in(user)
    project.add_role(user, role)
  end

  context 'for developer' do
    given(:role) { :developer }

    scenario 'to be disallowed to view' do
      visit project_settings_ci_cd_path(project)

      expect(page.status_code).to eq(404)
    end
  end

  context 'for master' do
    given(:role) { :master }

    scenario 'be allowed to change' do
      visit project_settings_ci_cd_path(project)

      fill_in('Test coverage parsing', with: 'coverage_regex')
      click_on 'Save changes'

      expect(page.status_code).to eq(200)
      expect(page).to have_button('Save changes', disabled: false)
      expect(page).to have_field('Test coverage parsing', with: 'coverage_regex')
    end

    scenario 'updates auto_cancel_pending_pipelines' do
      visit project_settings_ci_cd_path(project)

      page.check('Auto-cancel redundant, pending pipelines')
      click_on 'Save changes'

      expect(page.status_code).to eq(200)
      expect(page).to have_button('Save changes', disabled: false)

      checkbox = find_field('project_auto_cancel_pending_pipelines')
      expect(checkbox).to be_checked
    end

    describe 'Auto DevOps' do
      it 'update auto devops settings' do
        visit project_settings_ci_cd_path(project)

        fill_in('project_auto_devops_attributes_domain', with: 'test.com')
        page.choose('project_auto_devops_attributes_enabled_false')
        click_on 'Save changes'

        expect(page.status_code).to eq(200)
        expect(project.auto_devops).to be_present
        expect(project.auto_devops).not_to be_enabled
      end
    end
  end
end
