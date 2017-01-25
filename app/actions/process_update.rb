module VCAP::CloudController
  class ProcessUpdate
    class InvalidProcess < StandardError; end

    def initialize(user_audit_info)
      @user_audit_info = user_audit_info
    end

    def update(process, message)
      process.db.transaction do
        process.lock!

        process.command              = message.command if message.requested?(:command)
        process.ports                = message.ports if message.requested?(:ports)
        process.health_check_type    = message.health_check_type if message.requested?(:health_check_type)
        process.health_check_timeout = message.health_check_timeout if message.requested?(:health_check_timeout)

        process.save

        Repositories::ProcessEventRepository.record_update(process, @user_audit_info, message.audit_hash)
      end
    rescue Sequel::ValidationFailed => e
      raise InvalidProcess.new(e.message)
    end
  end
end
