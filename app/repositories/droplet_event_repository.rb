module VCAP::CloudController
  module Repositories
    class DropletEventRepository
      CENSORED_FIELDS   = [:environment_variables].freeze
      CENSORED_MESSAGE  = 'PRIVATE DATA HIDDEN'.freeze
      def self.record_create_by_staging(droplet, user_audit_info, request_attrs, v3_app_name, space_guid, org_guid)
        Loggregator.emit(droplet.app_guid, "Creating droplet for app with guid #{droplet.app_guid}")

        metadata = {
          droplet_guid: droplet.guid,
          package_guid: droplet.package.guid,
          request:      droplet_audit_hash(request_attrs)
        }

        Event.create(
          type:              'audit.app.droplet.create',
          actor:             user_audit_info.user_guid,
          actor_type:        'user',
          actor_name:        user_audit_info.user_email,
          actee:             droplet.app_guid,
          actee_type:        'app',
          actee_name:        v3_app_name,
          timestamp:         Sequel::CURRENT_TIMESTAMP,
          metadata:          metadata,
          space_guid:        space_guid,
          organization_guid: org_guid
        )
      end

      def self.record_create_by_copying(new_droplet_guid, source_droplet_guid, user_audit_info, v3_app_guid, v3_app_name, space_guid, org_guid)
        Loggregator.emit(v3_app_guid, "Creating droplet for app with guid #{v3_app_guid}")

        metadata = {
          droplet_guid: new_droplet_guid,
          request:      {
            source_droplet_guid: source_droplet_guid
          }
        }

        Event.create(
          type:              'audit.app.droplet.create',
          actor:             user_audit_info.user_guid,
          actor_type:        'user',
          actor_name:        user_audit_info.user_email,
          actee:             v3_app_guid,
          actee_type:        'app',
          actee_name:        v3_app_name,
          timestamp:         Sequel::CURRENT_TIMESTAMP,
          metadata:          metadata,
          space_guid:        space_guid,
          organization_guid: org_guid
        )
      end

      def self.record_delete(droplet, user_audit_info, v3_app_name, space_guid, org_guid)
        Loggregator.emit(droplet.app_guid, "Deleting droplet for app with guid #{droplet.app_guid}")

        metadata = { droplet_guid: droplet.guid }

        Event.create(
          type:              'audit.app.droplet.delete',
          actor:             user_audit_info.user_guid,
          actor_type:        'user',
          actor_name:        user_audit_info.user_email,
          actee:             droplet.app_guid,
          actee_type:        'app',
          actee_name:        v3_app_name,
          timestamp:         Sequel::CURRENT_TIMESTAMP,
          metadata:          metadata,
          space_guid:        space_guid,
          organization_guid: org_guid
        )
      end

      # Emit this event once we have droplet download capability
      def self.record_download(droplet, user_audit_info, v3_app_name, space_guid, org_guid)
        Loggregator.emit(droplet.app_guid, "Downloading droplet for app with guid #{droplet.app_guid}")

        metadata = { droplet_guid: droplet.guid }

        Event.create(
          type:              'audit.app.droplet.download',
          actor:             user_audit_info.user_guid,
          actor_type:        'user',
          actor_name:        user_audit_info.user_email,
          actee:             droplet.app_guid,
          actee_type:        'app',
          actee_name:        v3_app_name,
          timestamp:         Sequel::CURRENT_TIMESTAMP,
          metadata:          metadata,
          space_guid:        space_guid,
          organization_guid: org_guid
        )
      end

      def self.droplet_audit_hash(request_attrs)
        request_attrs.dup.tap do |attr|
          CENSORED_FIELDS.map(&:to_s).each do |censored|
            attr[censored] = CENSORED_MESSAGE if attr.key?(censored)
          end
        end
      end
    end
  end
end
