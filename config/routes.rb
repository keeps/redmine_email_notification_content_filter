RedmineApp::Application.routes.draw do
  resources :projects do
    resource :manage_email_notification_content_filter, :controller => 'email_notification_content_filter', :only => [:update]
  end
end
