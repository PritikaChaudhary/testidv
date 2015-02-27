class LoanUrl
  include MongoMapper::Document
  key :loan_id, :required=>true
  key :email, :required=>true
  key :name, :required=>true
  key :date, :required=>true
  key :url, :required=>true
  key :disabled
  belongs_to :loan

end