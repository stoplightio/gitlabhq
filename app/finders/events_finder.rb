class EventsFinder
  prepend FinderMethods
  prepend FinderWithCrossProjectAccess
  attr_reader :source, :params, :current_user, :projects

  requires_cross_project_access unless: -> { source.is_a?(Project) }

  # Used to filter Events
  #
  # Arguments:
  #   source - which user or project to scope events to
  #   current_user - only return events for projects visible to this user
  #   projects - only return events for these projects
  #   params:
  #     action: string
  #     target_type: string
  #     before: datetime
  #     after: datetime
  #
  def initialize(params = {})
    @source = params.delete(:source)
    @current_user = params.delete(:current_user)
    @projects = params.delete(:projects)
    @params = params
  end

  def execute
    if source
      events = source.events
    else
      events = Event.unscoped.recent
    end

    events = by_projects(events)
    events = by_current_user_access(events)
    events = by_action(events)
    events = by_target_type(events)
    events = by_created_at_before(events)
    events = by_created_at_after(events)

    events.with_associations
  end

  private

  def by_projects(events)
    return events unless projects

    events.in_projects(projects)
  end

  def by_current_user_access(events)
    return events unless current_user

    events.merge(ProjectsFinder.new(current_user: current_user).execute)
      .joins(:project)
  end

  def by_action(events)
    return events unless Event::ACTIONS[params[:action]]

    events.where(action: Event::ACTIONS[params[:action]])
  end

  def by_target_type(events)
    return events unless Event::TARGET_TYPES[params[:target_type]]

    events.where(target_type: Event::TARGET_TYPES[params[:target_type]])
  end

  def by_created_at_before(events)
    return events unless params[:before]

    events.where('events.created_at < ?', params[:before].beginning_of_day)
  end

  def by_created_at_after(events)
    return events unless params[:after]

    events.where('events.created_at > ?', params[:after].end_of_day)
  end
end
