class EmailNotificationContentFilterConfig < ActiveRecord::Base
  unloadable

  belongs_to :project
  belongs_to :custom_field, :conditions => {:type => 'IssueCustomField'}

  scope :static_fields, :conditions => 'field_name IS NOT NULL'
  scope :issue_custom_fields, :conditions => 'custom_field_id IS NOT NULL'

  class ConfigurableField
    attr_accessor :name, :active, :label, :is_static

    def initialize(fields = {})
      fields.each do |field_name, field_value|
        self.send("#{field_name}=", field_value)
      end
    end

    def active?
      !active.blank?
    end

    def is_static?
      is_static == 'true' || is_static == true
    end
  end

  def self.configurable_fields_for_project(project)
    saved_static_fields_for_project = saved_static_configurable_fields_by_name(project)
    saved_configurable_issue_custom_fields_for_project = saved_configurable_issue_custom_fields_by_id(project)

    static_configurable_fields(project, saved_static_fields_for_project) + configurable_issue_custom_fields(project, saved_configurable_issue_custom_fields_for_project)
  end

  def self.parse_configured_fields(configurable_fields_params)
    configurable_fields_params.values.map do |configurable_field_param|
      ConfigurableField.new(:name => configurable_field_param[:name], :active => configurable_field_param[:active], :is_static => configurable_field_param[:is_static])
    end
  end

  def self.update(project, sent_configured_fields)
    to_save = []
    to_delete = []
  
    # Delete configuration for static fields that are not in post
    static_fields.find_all_by_project_id(project.id).each do |existent_field|
      unless sent_configured_fields.find {|sent_field| sent_field.is_static? && sent_field.name == existent_field.field_name}
        to_delete << existent_field
      end
    end

    available_issue_custom_field_ids = project.issue_custom_fields.map(&:id)

    # Delete configuration for custom fields that are not available for this project
    issue_custom_fields.find_all_by_project_id(project.id).each do |existent_field|
      unless available_issue_custom_field_ids.include?(existent_field.custom_field_id)
        to_delete << existent_field
      end
    end

    # Update configuration
    sent_configured_fields.each do |sent_field|
      if sent_field.is_static?
        record_to_save = find_or_initialize_by_project_id_and_field_name(project.id, sent_field.name)
      else
        next unless available_issue_custom_field_ids.include?(sent_field.name.to_i)
        record_to_save = find_or_initialize_by_project_id_and_custom_field_id(project.id, sent_field.name)
      end

      record_to_save.active = sent_field.active?
      to_save << record_to_save
    end

    transaction do
      to_delete.map(&:destroy)
      to_save.map(&:save)
    end
  end

  private

  def self.saved_static_configurable_fields_by_name(project)
    static_fields.find_all_by_project_id(project.id).group_by(&:field_name)
  end

  def self.saved_configurable_issue_custom_fields_by_id(project)
    issue_custom_fields.find_all_by_project_id(project.id).group_by(&:custom_field_id)
  end

  def self.saved_static_configurable_field_is_active?(name, saved_fields_for_project_by_name)
    return true unless saved_fields_for_project_by_name.has_key?(name)
    saved_fields_for_project_by_name[name].first.active?
  end

  def self.saved_configurable_issue_custom_field_is_active?(field_id, saved_fields_for_project_by_id)
    return true unless saved_fields_for_project_by_id.has_key?(field_id)
    saved_fields_for_project_by_id[field_id].first.active?
  end

  def self.static_configurable_fields(project, saved_fields_for_project_by_name)
    [
      ConfigurableField.new(:name => 'author', :active => saved_static_configurable_field_is_active?('author', saved_fields_for_project_by_name), :label => I18n.t(:field_author), :is_static => true),
      ConfigurableField.new(:name => 'status', :active => saved_static_configurable_field_is_active?('status', saved_fields_for_project_by_name), :label => I18n.t(:field_status), :is_static => true),
      ConfigurableField.new(:name => 'priority', :active => saved_static_configurable_field_is_active?('priority', saved_fields_for_project_by_name), :label => I18n.t(:field_priority), :is_static => true),
      ConfigurableField.new(:name => 'assigned_to', :active => saved_static_configurable_field_is_active?('assigned_to', saved_fields_for_project_by_name), :label => I18n.t(:field_assigned_to), :is_static => true),
      ConfigurableField.new(:name => 'category', :active => saved_static_configurable_field_is_active?('category', saved_fields_for_project_by_name), :label => I18n.t(:field_category), :is_static => true),
      ConfigurableField.new(:name => 'fixed_version', :active => saved_static_configurable_field_is_active?('fixed_version', saved_fields_for_project_by_name), :label => I18n.t(:field_fixed_version), :is_static => true)
    ]
  end

  def self.configurable_issue_custom_fields(project, saved_fields_for_project_by_id)
    project.issue_custom_fields.map do |issue_custom_field|
      ConfigurableField.new(:name => issue_custom_field.id, :active => self.saved_configurable_issue_custom_field_is_active?(issue_custom_field.id, saved_fields_for_project_by_id) , :label => issue_custom_field.name, :is_static => false)
    end
  end
end
