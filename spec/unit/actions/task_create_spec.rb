require 'spec_helper'
require 'actions/task_create'

module VCAP::CloudController
  describe TaskCreate do
    subject(:task_create_action) { described_class.new(config) }
    let(:config) { {} }

    describe '#create' do
      let(:app) { AppModel.make }
      let(:space) { app.space }
      let(:droplet) { DropletModel.make(app_guid: app.guid, state: DropletModel::STAGED_STATE) }
      let(:command) { 'bundle exec rake panda' }
      let(:name) { 'my_task_name' }
      let(:message) { TaskCreateMessage.new name: name, command: command, memory_in_mb: 1024, environment_variables: environment_variables }
      let(:client) { instance_double(VCAP::CloudController::Diego::NsyncClient) }
      let(:environment_variables) { { 'unicorn' => 'magic' } }

      before do
        locator = CloudController::DependencyLocator.instance
        allow(locator).to receive(:nsync_client).and_return(client)
        allow(client).to receive(:desire_task).and_return(nil)

        app.droplet = droplet
        app.save
      end

      it 'creates and returns a task using the given app and its droplet' do
        task = task_create_action.create(app, message)

        expect(task.app).to eq(app)
        expect(task.droplet).to eq(droplet)
        expect(task.command).to eq(command)
        expect(task.name).to eq(name)
        expect(task.memory_in_mb).to eq(1024)
        expect(TaskModel.count).to eq(1)
        expect(task.environment_variables).to eq(environment_variables)
      end

      it "sets the task state to 'RUNNING'" do
        task = task_create_action.create(app, message)

        expect(task.state).to eq(TaskModel::RUNNING_STATE)
      end

      it 'tells diego to make the task' do
        task = task_create_action.create(app, message)

        expect(client).to have_received(:desire_task).with(task)
      end

      it 'creates an app usage event for TASK_STARTED' do
        task = task_create_action.create(app, message)

        event = AppUsageEvent.last
        expect(event.state).to eq('TASK_STARTED')
        expect(event.task_guid).to eq(task.guid)
      end

      describe 'default values' do
        let(:message) { TaskCreateMessage.new name: name, command: command }

        it 'sets memory_in_mb to configured :default_app_memory' do
          config[:default_app_memory] = 1234

          task = task_create_action.create(app, message)

          expect(task.memory_in_mb).to eq(1234)
        end
      end

      context 'when the app does not have an assigned droplet' do
        let(:app_with_no_droplet) { AppModel.make }

        it 'raises a NoAssignedDroplet error' do
          expect {
            task_create_action.create(app_with_no_droplet, message)
          }.to raise_error(TaskCreate::NoAssignedDroplet, 'Task must have a droplet. Specify droplet or assign current droplet to app.')
        end
      end

      context 'when the task is invalid' do
        before do
          allow_any_instance_of(TaskModel).to receive(:save).and_raise(Sequel::ValidationFailed.new('booooooo'))
        end

        it 'raises an InvalidTask error' do
          expect {
            task_create_action.create(app, message)
          }.to raise_error(TaskCreate::InvalidTask, 'booooooo')
        end
      end
    end
  end
end