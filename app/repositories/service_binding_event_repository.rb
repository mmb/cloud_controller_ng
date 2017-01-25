module VCAP::CloudController
  module Repositories
    class ServiceBindingEventRepository
      def self.record_create(service_binding, user_audit_info, request)
        attrs         = request.dup.stringify_keys
        attrs['data'] = 'PRIVATE DATA HIDDEN' if attrs.key?('data')

        record_event(
          type:            'audit.service_binding.create',
          service_binding: service_binding,
          user_audit_info: user_audit_info,
          metadata:        { request: attrs }
        )
      end

      def self.record_delete(service_binding, user_audit_info)
        record_event(
          type:            'audit.service_binding.delete',
          service_binding: service_binding,
          user_audit_info: user_audit_info
        )
      end

      class << self
        private

        def record_event(type:, service_binding:, user_audit_info:, metadata: {})
          Event.create(
            type:              type,
            actor:             user_audit_info.user_guid,
            actor_type:        'user',
            actor_name:        user_audit_info.user_email,
            actee:             service_binding.guid,
            actee_type:        'service_binding',
            actee_name:        '',
            space_guid:        service_binding.space.guid,
            organization_guid: service_binding.space.organization.guid,
            timestamp:         Sequel::CURRENT_TIMESTAMP,
            metadata:          metadata
          )
        end
      end
    end
  end
end
