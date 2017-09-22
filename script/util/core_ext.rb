class Object

  def try(*a, &b)
    __send__(*a, &b) unless self.nil?
  end

  def in?(enumerable)
    enumerable.include?(self)
  end

  def blank?
    respond_to?(:empty?) ? !!empty? : !self
  end

  def present?
    !blank?
  end

  def presence
    self if present?
  end

  def exclude?(obj)
    !include?(obj)
  end

end
