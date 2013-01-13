class CreateEmailNotificationContentFilterConfigs < ActiveRecord::Migration
  def change
    create_table :email_notification_content_filter_configs do |t|
      t.references :project
      t.string :field_name
      t.references :custom_field
      t.boolean :active
    end
    add_index :email_notification_content_filter_configs, :project_id, :name => :email_content_filter_config_project
    add_index :email_notification_content_filter_configs, :custom_field_id, :name => :email_content_filter_custom_field
  end
end
