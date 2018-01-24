require 'spec_helper'

feature 'Gcp Cluster', :js do
  include GoogleApi::CloudPlatformHelpers

  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    project.add_master(user)
    gitlab_sign_in(user)
    allow(Projects::ClustersController).to receive(:STATUS_POLLING_INTERVAL) { 100 }
  end

  context 'when user has signed with Google' do
    before do
      allow_any_instance_of(Projects::Clusters::GcpController)
        .to receive(:token_in_session).and_return('token')
      allow_any_instance_of(Projects::Clusters::GcpController)
        .to receive(:expires_at_in_session).and_return(1.hour.since.to_i.to_s)
    end

    context 'when user does not have a cluster and visits cluster index page' do
      before do
        visit project_clusters_path(project)

        click_link 'Add cluster'
        click_link 'Create on GKE'
      end

      context 'when user filled form with valid parameters' do
        before do
          allow_any_instance_of(GoogleApi::CloudPlatform::Client)
            .to receive(:projects_zones_clusters_create) do
            OpenStruct.new(
              self_link: 'projects/gcp-project-12345/zones/us-central1-a/operations/ope-123',
              status: 'RUNNING'
            )
          end

          allow(WaitForClusterCreationWorker).to receive(:perform_in).and_return(nil)

          fill_in 'cluster_provider_gcp_attributes_gcp_project_id', with: 'gcp-project-123'
          fill_in 'cluster_name', with: 'dev-cluster'
          click_button 'Create cluster'
        end

        it 'user sees a cluster details page and creation status' do
          expect(page).to have_content('Cluster is being created on Google Kubernetes Engine...')

          Clusters::Cluster.last.provider.make_created!

          expect(page).to have_content('Cluster was successfully created on Google Kubernetes Engine')
        end

        it 'user sees a error if something worng during creation' do
          expect(page).to have_content('Cluster is being created on Google Kubernetes Engine...')

          Clusters::Cluster.last.provider.make_errored!('Something wrong!')

          expect(page).to have_content('Something wrong!')
        end
      end

      context 'when user filled form with invalid parameters' do
        before do
          click_button 'Create cluster'
        end

        it 'user sees a validation error' do
          expect(page).to have_css('#error_explanation')
        end
      end
    end

    context 'when user does have a cluster and visits cluster page' do
      let(:cluster) { create(:cluster, :provided_by_gcp, projects: [project]) }

      before do
        visit project_cluster_path(project, cluster)
      end

      it 'user sees a cluster details page' do
        expect(page).to have_button('Save')
        expect(page.find(:css, '.cluster-name').value).to eq(cluster.name)
      end

      context 'when user disables the cluster' do
        before do
          page.find(:css, '.js-toggle-cluster').click
          click_button 'Save'
        end

        it 'user sees the successful message' do
          expect(page).to have_content('Cluster was successfully updated.')
        end
      end

      context 'when user changes cluster parameters' do
        before do
          fill_in 'cluster_platform_kubernetes_attributes_namespace', with: 'my-namespace'
          click_button 'Save changes'
        end

        it 'user sees the successful message' do
          expect(page).to have_content('Cluster was successfully updated.')
          expect(cluster.reload.platform_kubernetes.namespace).to eq('my-namespace')
        end
      end

      context 'when user destroy the cluster' do
        before do
          page.accept_confirm do
            click_link 'Remove integration'
          end
        end

        it 'user sees creation form with the successful message' do
          expect(page).to have_content('Cluster integration was successfully removed.')
          expect(page).to have_link('Add cluster')
        end
      end
    end
  end

  context 'when user has not signed with Google' do
    before do
      visit project_clusters_path(project)

      click_link 'Add cluster'
      click_link 'Create on GKE'
    end

    it 'user sees a login page' do
      expect(page).to have_css('.signin-with-google')
    end
  end
end
