class SortTask < ServicingDatabase
  self.table_name = "sort_task"
  belongs_to :task
  belongs_to :user
 

  
  def owner
    User.find(self.user_id)
  end
  
  def task
    Task.find(self.task_id)
  end
  
end
