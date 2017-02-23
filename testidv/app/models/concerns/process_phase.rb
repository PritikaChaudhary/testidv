class ProcessPhase < ServicingDatabase
  self.table_name = "trigger"
  has_many :process_items, class_name: "ProcessItem", foreign_key: "trigger_id"
     
end
