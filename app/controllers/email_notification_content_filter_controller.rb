class EmailNotificationContentFilterController < ApplicationController
  unloadable

  before_filter :find_project_by_project_id
  #before_filter :authorize

  helper :custom_fields

  def update
    configured_fields = EmailNotificationContentFilterConfig.parse_configured_fields(params[:resources])
    if request.put? && !configured_fields.blank? && EmailNotificationContentFilterConfig.update(@project, configured_fields)
      flash[:notice] = l(:notice_successful_update)
    else
      flash[:error] = l(:notice_email_notification_content_filter_failed_to_save_config)
    end

    redirect_to settings_project_path(@project, :tab => 'email_filter')
  end
end
