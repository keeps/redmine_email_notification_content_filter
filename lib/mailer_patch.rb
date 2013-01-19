module MailerPatch
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)

    base.class_eval do
      alias_method_chain :issue_add, :email_filter
      alias_method_chain :issue_edit, :email_filter
    end
  end

  module InstanceMethods
    # Copied from app/models/mailer.rb
    def issue_add_with_email_filter(issue)
      @issue_custom_field_values = issue.custom_field_values
      @static_fields_to_hide = {}

      if issue.project.module_enabled?(:email_notification_content_filter)
        project = issue.project
        email_content_filter_config = EmailNotificationContentFilterConfig.find_all_by_project_id(project.id)

        @static_fields_to_hide = EmailNotificationContentFilterConfig.static_field_to_hide_names(email_content_filter_config)
        
        issue_custom_field_to_remove_ids = EmailNotificationContentFilterConfig.issue_custom_field_to_remove_ids(email_content_filter_config)
        @issue_custom_field_values = @issue_custom_field_values.select {|custom_field_value| !issue_custom_field_to_remove_ids.include?(custom_field_value.custom_field.id) }
      end

      @issue_title = email_notification_content_filter_issue_title(issue.id, issue.project.name, issue.tracker.name, issue.status.name, issue.subject)
      @author_in_message_title = @static_fields_to_hide.include?('author') ? "" : issue.author
      s = email_notification_content_filter_subject(issue.id, issue.project.name, issue.tracker.name, issue.status.name, issue.subject)

      redmine_headers 'Project' => issue.project.identifier,
                      'Issue-Id' => issue.id,
                      'Issue-Author' => issue.author.login
      redmine_headers 'Issue-Assignee' => issue.assigned_to.login if issue.assigned_to
      message_id issue
      @author = issue.author
      @issue = issue
      @issue_url = url_for(:controller => 'issues', :action => 'show', :id => issue)

      recipients = issue.recipients
      cc = issue.watcher_recipients - recipients
      mail :to => recipients,
        :cc => cc,
        :subject => s
    end

    # Copied from app/models/mailer.rb
    def issue_edit_with_email_filter(journal)
      issue = journal.journalized.reload

      @issue_custom_field_values = issue.custom_field_values
      @static_fields_to_hide = {}

      if issue.project.module_enabled?(:email_notification_content_filter)
        project = issue.project
        email_content_filter_config = EmailNotificationContentFilterConfig.find_all_by_project_id(project.id)

        @static_fields_to_hide = EmailNotificationContentFilterConfig.static_field_to_hide_names(email_content_filter_config)
        
        issue_custom_field_to_remove_ids = EmailNotificationContentFilterConfig.issue_custom_field_to_remove_ids(email_content_filter_config)
        @issue_custom_field_values = @issue_custom_field_values.select {|custom_field_value| !issue_custom_field_to_remove_ids.include?(custom_field_value.custom_field.id) }
      end

      redmine_headers 'Project' => issue.project.identifier,
                      'Issue-Id' => issue.id,
                      'Issue-Author' => issue.author.login
      redmine_headers 'Issue-Assignee' => issue.assigned_to.login if issue.assigned_to
      message_id journal
      references issue
      @author = journal.user
      recipients = journal.recipients
      # Watchers in cc
      cc = journal.watcher_recipients - recipients
      
      @issue_title = email_notification_content_filter_issue_title(issue.id, issue.project.name, issue.tracker.name, issue.status.name, issue.subject)
      @author_in_message_title = @static_fields_to_hide.include?('author') ? "" : journal.user
      status_name = journal.new_value_for('status_id') ? issue.status.name : ""
      s = email_notification_content_filter_subject(issue.id, issue.project.name, issue.tracker.name, status_name, issue.subject)

      @issue = issue
      @journal = journal
      @issue_url = url_for(:controller => 'issues', :action => 'show', :id => issue, :anchor => "change-#{journal.id}")
      mail :to => recipients,
        :cc => cc,
        :subject => s
    end

    private
    def email_notification_content_filter_issue_title(issue_id, project_name, tracker_name, status_name, issue_subject)
      issue_title = "#{tracker_name} ##{issue_id}: #{issue_subject}"

      issue_title = "##{issue_id}"
      issue_title = "#{tracker_name} #{issue_title}" unless @static_fields_to_hide.include?('tracker_name')
      issue_title << ": #{issue_subject}" unless @static_fields_to_hide.include?('subject')
      issue_title
    end

    def email_notification_content_filter_subject(issue_id, project_name, tracker_name, status_name, issue_subject)
      subject_head = []
      subject_head << project_name unless @static_fields_to_hide.include?('project_name')
      subject_head << tracker_name unless @static_fields_to_hide.include?('tracker_name')
      if subject_head.empty?
        subject_head_str = "##{issue_id}"
      else
        subject_head_str = "#{subject_head.join(' - ')} ##{issue_id}"
      end

      subject_str = "[#{subject_head_str}]"
      subject_str << " (#{status_name})" unless @static_fields_to_hide.include?('status') || status_name.blank?
      subject_str << " #{issue_subject}" unless @static_fields_to_hide.include?('subject')
      subject_str
    end
  end
end
