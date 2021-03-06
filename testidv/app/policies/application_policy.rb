class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    #raise Pundit::NotAuthorizedError, "must be logged in" unless user
    @user = user
    @record = record
  end

  def index?
    user && user.role?(:Admin) || false
  end

  def show?
    scope.where(:id => record.id).exists?
  end

  def create?
    user && user.role?(:Admin) || false
  end

  def new?
    create?
  end

  def update?
    #raise Pundit::NotAuthorizedError, "must be logged in" unless user
    user && user.role?(:Admin) || false
  end

  def edit?
    update?
  end

  def destroy?
    user && user.role?(:Admin) || false
  end

  def scope
    Pundit.policy_scope!(user, record.class)
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope
    end
  end
end

