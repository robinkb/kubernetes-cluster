package config

import (
	"list"
	"strconv"
)

// By no means a complete Butane spec, but enough to get me going.
// The hidden fields are a workaround until associative lists are supported.
// See: https://cuetorials.com/cueology/futurology/associative-lists/
#Butane: {
	version: string
	variant: string

	storage: {
		_disks: [Device=_]: {
			device:     Device
			wipe_table: bool | *false
			_partitions: [Number=_]: {
				number:   strconv.ParseInt(Number, 0, 0)
				label:    string
				size_mib: int
				resize?:  bool | *false
			}
			partitions: list.Concat([ for key, obj in _partitions {[obj]}])
		}
		disks: list.Concat([ for key, obj in _disks {[obj]}])

		_filesystems: [Path=_]: {
			path:            Path
			device:          string
			format:          string
			wipe_filesystem: bool | *false
			with_mount_unit: bool | *true
		}
		filesystems: list.Concat([ for key, obj in _filesystems {[obj]}])

		_directories: [Path=_]: {
			path: Path
		}
		directories: list.Concat([ for key, obj in _directories {[obj]}])

		_files: [Path=_]: {
			path:  Path
			mode?: number
			contents?: {
				source?: string
				inline?: string
			}
			_append: [Name=_]: {
				_name:  Name
				inline: string
			}
			append: list.Concat([ for key, obj in _append {[obj]}])
		}
		files: list.Concat([ for key, obj in _files {[obj]}])
	}

	passwd: {
		_users: [Name=_]: {
			name: Name
			ssh_authorized_keys: [string, ...]
		}
		users: list.Concat([ for key, obj in _users {[obj]}])
	}

	systemd: {
		_units: [Name=_]: {
			name:      Name
			enabled:   bool
			mask?:     bool
			contents?: string
			dropins?: [{
				name:     string
				contents: string
			}]
		}
		units: list.Concat([ for key, obj in _units {[obj]}])
	}
}
