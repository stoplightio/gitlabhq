require 'spec_helper'

describe 'Project fork' do
  include ProjectForksHelper

  let(:user) { create(:user) }
  let(:project) { create(:project, :public, :repository) }

  before do
    sign_in user
  end

  it 'allows user to fork project' do
    visit project_path(project)

    expect(page).not_to have_css('a.disabled', text: 'Fork')
  end

  it 'disables fork button when user has exceeded project limit' do
    user.projects_limit = 0
    user.save!

    visit project_path(project)

    expect(page).to have_css('a.disabled', text: 'Fork')
  end

  context 'master in group' do
    let(:group) { create(:group) }

    before do
      group.add_master(user)
    end

    it 'allows user to fork project to group or to user namespace' do
      visit project_path(project)

      expect(page).not_to have_css('a.disabled', text: 'Fork')

      click_link 'Fork'

      expect(page).to have_css('.fork-thumbnail', count: 2)
      expect(page).not_to have_css('.fork-thumbnail.disabled')
    end

    it 'allows user to fork project to group and not user when exceeded project limit' do
      user.projects_limit = 0
      user.save!

      visit project_path(project)

      expect(page).not_to have_css('a.disabled', text: 'Fork')

      click_link 'Fork'

      expect(page).to have_css('.fork-thumbnail', count: 2)
      expect(page).to have_css('.fork-thumbnail.disabled')
    end

    it 'links to the fork if the project was already forked within that namespace' do
      forked_project = fork_project(project, user, namespace: group, repository: true)

      visit new_project_fork_path(project)

      expect(page).to have_css('div.forked', text: group.full_name)

      click_link group.full_name

      expect(current_path).to eq(project_path(forked_project))
    end
  end
end
