class Task < ServicingDatabase
  self.table_name = "task"
  belongs_to :loan
  belongs_to :user
  belongs_to :process_item, class_name: "ProcessItem", foreign_key: "taskItem_id"
  
  has_many :task_has_users  
  before_save :default_values

  validates :description, :presence => true
  validates :addedBy, :presence => true
  validates :assignedTo, :presence => true
  validates :date, :presence => true
  validates :dueDate, :presence => true
  validates_presence_of :finalNote, :if => :complete


  def default_values
    t = Time.now
    self.date ||= t.strftime("%Y-%m-%d")
    self.dueDate ||= 7.days.from_now.strftime("%Y-%m-%d")
    
    
  end

  
  def owner
    User.find(self.addedBy)
  end
  
  
  def loan_name
    loan = self.loan
    if loan
      loan.name
    else
      'General Task'
    end

  end

  def complete
    if !self.completed.blank? && self.completed !='0000-00-00' 
      return true
    else
      return false
    end
  end
  
  

  
  def priority_text
    case self.priority
      when 1
        return "Normal"
      when 2
        return 'Medium'
      when 3 
        return 'High'
      when 4
        return 'Now'
     end
  end

  def style
    'none'
  end

  def selected_users
    output = []
    self.task_has_users.each do |user|
      output<<user.user_id
    end
    output
  end


  def is_process?
    if !self.loan_id.blank?
      !self.taskItem_id.blank? || (!self.trigger_id.blank? && !self.processOrder.blank?)
    else
      false
    end
  end
  
  def process_phase
    if !self.trigger_id.blank?
      return self.trigger_id
    end
    if !self.process_item.blank?
      return self.process_item.trigger_id
    end  
  end 
  
  
  def next_tasks
    # return immediately if the task is not part of the process
    if !self.is_process?
      return []
    end

    #return immediately if there are tasks in the phase which are not complete
    check = Task.where(
      "`loan_id`=? and `id`<> ? and (`completed` = '0000-00-00' or `completed` IS NULL) and (`taskItem_id` IS NOT NULL || (`trigger_id` IS NOT NULL && `processOrder` IS NOT NULL))",
        "#{self.loan_id}", "#{self.id}"
      )
     if !check.blank?
       check.each do |item|
         if item.process_item.blank?
           if !item.trigger_id.blank?
             return []
           end
         else
           if item.process_item.trigger_id == self.process_phase
             return []
           end
         end
       end
     end  




    #get the next process items if the task is manually entered 
    if !self.trigger_id.blank? && !self.processOrder.blank?
      #check for process items in the same phase
      process_items = ProcessItem.where("`trigger_id`=? and `processOrder`>?", "#{self.trigger_id}", "#{self.processOrder}").order('processOrder ASC')
      if process_items.blank?
        #move to the next phase
        process_items = ProcessItem.where("`trigger_id`=?", "#{self.trigger_id+1}").order('processOrder ASC')
        if process_items.blank?
          return []
        end  
      end
    end

    
    #get the next process items if the task is associated with a processItem 
    process_item = self.process_item
    if !process_item.blank?
      #check for process items in the same phase
      process_items = ProcessItem.where("`trigger_id`=? and `processOrder`>?", "#{process_item.trigger_id}", "#{process_item.processOrder}").order('processOrder ASC')
      if process_items.blank?
        #move to the next phase
        process_items = ProcessItem.where("`trigger_id`=?", "#{process_item.trigger_id+1}").order('processOrder ASC')
        if process_items.blank?
          return []
        end  
      end      
    end
    
    #filter the items that are only of the next processOrder
    next_items = []
    if !process_items.blank?
      order_num = process_items.first.processOrder
      process_items.each do |item|
        if item.processOrder == order_num
          next_items.push(item)
        end
      end
    end
    return next_items
    
  end #next_tasks
  
  
  
  
end
