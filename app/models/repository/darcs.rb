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

require 'redmine/scm/adapters/darcs_adapter'

class Repository::Darcs < Repository
  validates_presence_of :url, :log_encoding

  ATTRIBUTE_KEY_NAMES = {
      "url"          => "Root directory",
      "log_encoding" => "Commit messages encoding",
    }
  def self.human_attribute_name(attribute_key_name)
    ATTRIBUTE_KEY_NAMES[attribute_key_name] || super
  end

  def self.scm_adapter_class
    Redmine::Scm::Adapters::DarcsAdapter
  end

  def self.scm_name
    'Darcs'
  end

  def entry(path=nil, identifier=nil)
    patch = identifier.nil? ? nil : changesets.find_by_revision(identifier)
    scm.entry(path, patch.nil? ? nil : patch.scmid)
  end

  def entries(path=nil, identifier=nil)
    patch = identifier.nil? ? nil : changesets.find_by_revision(identifier)
    entries = scm.entries(path, patch.nil? ? nil : patch.scmid)
    if entries
      entries.each do |entry|
        # Search the DB for the entry's last change
        changeset = changesets.find_by_scmid(entry.lastrev.scmid) if entry.lastrev && !entry.lastrev.scmid.blank?
        if changeset
          entry.lastrev.identifier = changeset.revision
          entry.lastrev.name = changeset.revision
          entry.lastrev.time = changeset.committed_on
          entry.lastrev.author = changeset.committer
        end
      end
    end
    entries
  end

  def cat(path, identifier=nil)
    patch = identifier.nil? ? nil : changesets.find_by_revision(identifier.to_s)
    scm.cat(path, patch.nil? ? nil : patch.scmid)
  end

  def diff(path, rev, rev_to)
    patch_from = changesets.find_by_revision(rev)
    return nil if patch_from.nil?
    patch_to = changesets.find_by_revision(rev_to) if rev_to
    if path.blank?
      path = patch_from.changes.collect{|change| change.path}.join(' ')
    end
    patch_from ? scm.diff(path, patch_from.scmid, patch_to ? patch_to.scmid : nil) : nil
  end

  def fetch_changesets
    scm_info = scm.info
    if scm_info
      db_last_id = latest_changeset ? latest_changeset.scmid : nil
      next_rev = latest_changeset ? latest_changeset.revision.to_i + 1 : 1
      # latest revision in the repository
      scm_revision = scm_info.lastrev.scmid
      unless changesets.find_by_scmid(scm_revision)
        revisions = scm.revisions('', db_last_id, nil, :with_path => true)
        transaction do
          revisions.reverse_each do |revision|
            changeset = Changeset.create(:repository => self,
                                         :revision => next_rev,
                                         :scmid => revision.scmid,
                                         :committer => revision.author,
                                         :committed_on => revision.time,
                                         :comments => revision.message)

            revision.paths.each do |change|
              changeset.create_change(change)
            end
            next_rev += 1
          end if revisions
        end
      end
    end
  end
end
