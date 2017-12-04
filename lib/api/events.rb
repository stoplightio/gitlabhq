module API
  class Events < Grape::API
    include PaginationParams

    helpers do
      params :event_filter_params do
        optional :action, type: String, values: Event.actions, desc: 'Event action to filter on'
        optional :target_type, type: String, values: Event.target_types, desc: 'Event target type to filter on'
        optional :before, type: Date, desc: 'Include only events created before this date'
        optional :after, type: Date, desc: 'Include only events created after this date'
      end

      params :sort_params do
        optional :sort, type: String, values: %w[asc desc], default: 'desc',
                        desc: 'Return events sorted in ascending and descending order'
      end

      def present_events(events)
        events = events.reorder(created_at: params[:sort])

        present paginate(events), with: Entities::Event
      end
    end

    resource :events do
      desc "List currently authenticated user's events" do
        detail 'This feature was introduced in GitLab 9.3.'
        success Entities::Event
      end
      params do
        use :pagination
        use :event_filter_params
        use :sort_params
      end
      get do
        authenticate!

        projects =
          if params[:filter] == "starred"
            ProjectsFinder.new(current_user: current_user, params: { starred: true }).execute
          else
            current_user.authorized_projects
          end

        events = EventsFinder.new(params.merge(projects: projects)).execute

        present_events(events)
      end
    end

    params do
      requires :id, type: String, desc: 'The ID or Username of the user'
    end
    resource :users do
      desc 'Get the contribution events of a specified user' do
        detail 'This feature was introduced in GitLab 8.13.'
        success Entities::Event
      end
      params do
        use :pagination
        use :event_filter_params
        use :sort_params
      end
      get ':id/events' do
        user = find_user(params[:id])
        not_found!('User') unless user

        events = EventsFinder.new(params.merge(source: user, current_user: current_user)).execute.preload(:author, :target)

        present_events(events)
      end
    end

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: API::PROJECT_ENDPOINT_REQUIREMENTS do
      desc "List a Project's visible events" do
        success Entities::Event
      end
      params do
        use :pagination
        use :event_filter_params
        use :sort_params
      end
      get ":id/events" do
        events = EventsFinder.new(params.merge(source: user_project, current_user: current_user)).execute.preload(:author, :target)

        present_events(events)
      end
    end

    params do
      requires :id, type: String, desc: 'The ID of a group'
    end
    resource :groups do
      desc "List a Group's visible events" do
        success Entities::Event
      end
      params do
        use :pagination
        use :event_filter_params
        use :sort_params
      end
      get ":id/events" do
        group = find_group!(params[:id])
        projects = GroupProjectsFinder.new(group: group, current_user: current_user).execute
        events = EventsFinder.new(params.merge(projects: projects)).execute

        present_events(events)
      end
    end
  end
end
