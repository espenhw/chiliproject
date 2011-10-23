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

class AllUsers < Group
  def validate_on_create
    # There should be only one AllUsers in the database
    errors.add_to_base 'An all users group already exists.' if AllUsers.find(:first)
  end

  def available_custom_fields
    []
  end

  def name(*args); I18n.t(:label_group_all_users) end

  def to_s
    name
  end
end
