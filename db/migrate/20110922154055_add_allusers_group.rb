#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2011 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class AddAllusersGroup < ActiveRecord::Migration
  def self.up
    group = Group.new(:lastname => "All Users")
    group.id = Group::ALL_USERS
    group.users = User.all()
    group.save
  end

  def self.down
    group = Group.find(Group::ALL_USERS)
    group.delete
  end
end
