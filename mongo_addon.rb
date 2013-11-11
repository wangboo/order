module Mongoid::Document
  
  def to_s
    msg = "obj_id=#{object_id}, _id=#{self[:_id]}, "
    fields.each{|name| msg<<"#{name[0]}=#{self[name[0]]}, " if name[0].is_a? String}
    msg
  end
  
  def == other
    id == other.id
  end
  
end