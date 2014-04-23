module MailerPatch
    def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)

    base.class_eval do
      alias_method_chain :issue_add, :email_filter
      alias_method_chain :issue_edit, :email_filter
    end
  end

  module InstanceMethods

    def issue_add_with_email_filter(issue)
	if issue.project.module_enabled?('email_notification_content_filter')
		if Setting.plugin_redmine_email_notification_content_filter['removeDescription']
			issue.description=""
		end
		if Setting.plugin_redmine_email_notification_content_filter['removeSubject']
			issue.subject=""
		end
                if Setting.plugin_redmine_email_notification_content_filter['removeCustomField']
                        issue.custom_field_values.each {|c| c.custom_field.name=""}
                        issue.custom_field_values.each {|c| c.value=""}
                end
	end
	issue_add_without_email_filter(issue)
    end

    def issue_edit_with_email_filter(journal)
	if Rails::VERSION::MAJOR >= 3
		     issue = journal.journalized.reload
			if issue.project.module_enabled?('email_notification_content_filter')
			if Setting.plugin_redmine_email_notification_content_filter['removeDescription']
				issue.description=""
			end
			if Setting.plugin_redmine_email_notification_content_filter['removeSubject']
				issue.subject=""
			end
                	if Setting.plugin_redmine_email_notification_content_filter['removeCustomField']
                        	issue.custom_field_values.each {|c| c.custom_field.name=""}
                        	issue.custom_field_values.each {|c| c.value=""}
                	end
			end
		    redmine_headers 'Project' => issue.project.identifier,
				    'Issue-Id' => issue.id,
				    'Issue-Author' => issue.author.login
		    redmine_headers 'Issue-Assignee' => issue.assigned_to.login if issue.assigned_to
		    message_id journal
		    references issue
                    if Setting.plugin_redmine_email_notification_content_filter['removeNote']
			journal.notes=""
	    	    end
		    @author = journal.user
		    recipients = journal.recipients
		    # Watchers in cc
		    cc = journal.watcher_recipients - recipients
		    s = "[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] "
		    s << "(#{issue.status.name}) " if journal.new_value_for('status_id')
		    s << issue.subject
		    @issue = issue
		    @journal = journal
		    @issue_url = url_for(:controller => 'issues', :action => 'show', :id => issue, :anchor => "change-#{journal.id}")
		    mail :to => recipients,
		      :cc => cc,
		      :subject => s
	else
		issue = journal.journalized.reload
		if issue.project.module_enabled?('email_notification_content_filter')
			if Setting.plugin_redmine_email_notification_content_filter['removeDescription']
				issue.description=""
			end
			if Setting.plugin_redmine_email_notification_content_filter['removeSubject']
				issue.subject=""
			end
	                if Setting.plugin_redmine_email_notification_content_filter['removeCustomField']
                        	issue.custom_field_values.each {|c| c.custom_field.name=""}
                        	issue.custom_field_values.each {|c| c.value=""}
                	end
		end
	    redmine_headers 'Project' => issue.project.identifier,
		            'Issue-Id' => issue.id,
		            'Issue-Author' => issue.author.login
	    redmine_headers 'Issue-Assignee' => issue.assigned_to.login if issue.assigned_to
	    message_id journal
	    references issue
	    if Setting.plugin_redmine_email_notification_content_filter['removeNote']
		journal.notes=""
	    end
	    @author = journal.user
	    recipients issue.recipients
	    # Watchers in cc
	    cc(issue.watcher_recipients - @recipients)
	    s = "[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] "
	    s << "(#{issue.status.name}) " if journal.new_value_for('status_id')
	    s << issue.subject
	    subject s
	    body :issue => issue,
		 :journal => journal,
		 :issue_url => url_for(:controller => 'issues', :action => 'show', :id => issue, :anchor => "change-#{journal.id}")

	    render_multipart('issue_edit', body)
	end
    end

  end
  end
