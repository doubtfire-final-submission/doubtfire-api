require 'test_helper'

class GroupsTest < ActiveSupport::TestCase
  include Rack::Test::Methods
  include TestHelpers::AuthHelper
  include TestHelpers::JsonHelper
  include TestHelpers::TestFileHelper

  def app
    Rails.application
  end

#   def test_get_groups
#     # The GET we are testing
#     unit_id = rand(1..Unit.all.length)

#   end

  def test_group_submission_with_extensions
    unit = Unit.first

    group_set = GroupSet.create!({name: 'test_group_submission_with_extensions', unit: unit})
    group_set.save!

    group = Group.create!({group_set: group_set, name: 'test_group_submission_with_extensions', tutorial: unit.tutorials.first, number: 0})

    group.add_member(unit.active_projects[0])
    group.add_member(unit.active_projects[1])
    group.add_member(unit.active_projects[2])

    td = TaskDefinition.new({
        unit_id: unit.id,
        name: 'Task to switch from ind to group after submission',                    
        description: 'test def',
        weighting: 4,
        target_grade: 0,
        start_date: Time.zone.now - 1.week,
        target_date: Time.zone.now - 1.day,
        due_date: Time.zone.now + 1.week,
        abbreviation: 'TaskSwitchIndGrp',
        restrict_status_updates: false,
        upload_requirements: [ { "key" => 'file0', "name" => 'Shape Class', "type" => 'code' } ],
        plagiarism_warn_pct: 0.8,
        is_graded: false,
        max_quality_pts: 0,
        group_set: group_set
      })
    assert td.save!

    data_to_post = {
      trigger: 'ready_to_mark'
    }

    data_to_post = with_file('test_files/submissions/test.sql', 'text/plain', data_to_post)

    project = group.projects.first

    post with_auth_token "/api/projects/#{project.id}/task_def_id/#{td.id}/extension", project.student
    assert_equal 201, last_response.status

    post "/api/projects/#{project.id}/task_def_id/#{td.id}/submission", with_auth_token(data_to_post, project.student)
    assert_equal 201, last_response.status

    group.reload
    group.projects.each do |proj|
        task = proj.task_for_task_definition(td)
        assert_equal TaskStatus.ready_to_mark, task.task_status
    end

    td.destroy
    group_set.destroy
  end

end
