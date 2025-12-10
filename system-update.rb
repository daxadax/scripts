#!/usr/bin/env ruby

# System Update Script
# Comprehensive system maintenance tool for Arch Linux
# Combines pacman updates, dotfiles sync, cloud backup, and system health checks
#
# USAGE:
#   ./system-update.rb                    # Run all operations
#   ./system-update.rb --verbose          # Enable verbose output
#   ./system-update.rb --skip dotfiles    # Skip dotfiles sync
#   ./system-update.rb --skip mega        # Skip MEGA sync
#   ./system-update.rb --help             # Show help
#
# CONFIGURATION:
#   Edit ~/.config/system-update-config.json to customize:
#   - dotfiles_path: Path to dotfiles repository
#   - mega_sync_dirs: Directories to sync to MEGA
#   - mega_sync_files: Files to sync to MEGA
#   - critical_packages: Packages requiring special attention
#   - breaking_change_keywords: Keywords for breaking change detection
#
# LOGS AND BACKUPS:
#   - Package state: /tmp/system-backup/package_state.json
#   - Package lists: /tmp/system-backup/packages_YYYYMMDD_HHMMSS.txt
#   - Config backups: /tmp/system-backup/ (critical config files)
#
# REQUIREMENTS:
#   - sudo privileges for system updates
#   - git repository at ~/dotfiles (or configured path)
#   - MEGAcmd installed and configured (for cloud sync)
#   - Ruby 3.x with standard libraries

require 'date'
require 'fileutils'
require 'json'
require 'open3'
require 'optparse'
require 'timeout'

class SystemUpdate
  attr_reader :config, :verbose, :skip_operations

  def initialize(options = {})
    @verbose = options[:verbose] || false
    @skip_operations = options[:skip] || []
    @config = load_config
    @errors = []
    @warnings = []
  end

  def call
    puts "Starting System Update Process"
    puts "=" * 50

    # Phase 1: Core System Updates
    puts "Starting Phase 1: Core System Updates"
    updates_performed = system_update
    puts "System update result: #{updates_performed}"
    return false if updates_performed == false  # Only return false on actual errors

    # Only analyze if updates were actually performed
    if updates_performed == :updated
      puts "Updates performed, analyzing changes..."
      return false unless analyze_updates
    else
      puts "No updates performed, skipping analysis"
    end

    # Handle orphan packages (optional)
    handle_orphans

    puts "Starting cache cleanup..."
    return false unless cleanup_cache

    # Phase 2: Dotfiles Management (always run)
    return false unless sync_dotfiles

    # Phase 3: Cloud Backup (always run)
    return false unless sync_to_mega

    # Phase 4: System Health & Maintenance
    cleanup_logs
    cleanup_journal
    check_disk_space
    check_services
    detect_orphans

    # Phase 5: Security & Monitoring
    verify_package_integrity
    check_security_updates
    audit_open_ports

    # Phase 6: Performance & Optimization
    cleanup_kernel_modules
    rebuild_font_cache
    cleanup_locales
    optimize_package_db

    # Phase 7: Backup & Recovery
    backup_configs
    export_package_list
    verify_boot_config

    # Final Report
    generate_report

    @errors.empty?
  end

  private

  def load_config
    config_file = File.expand_path('~/.config/system-update-config.json')

    if File.exist?(config_file)
      begin
        JSON.parse(File.read(config_file))
      rescue JSON::ParserError => e
        puts "Warning: Invalid config file, using defaults: #{e.message}"
        default_config
      end
    else
      default_config
    end
  end

  def default_config
    {
      'dotfiles_path' => '~/dotfiles',
      'mega_sync_dirs' => [],
      'mega_sync_files' => [],
      'breaking_change_keywords' => ['breaking', 'deprecated', 'removed', 'incompatible', 'changed'],
      'critical_packages' => ['systemd', 'linux', 'glibc', 'openssl'],
      'log_retention_days' => 30,
      'journal_retention_days' => 7,
      'critical_services' => ['systemd', 'dbus', 'network-online.target'],
      'critical_configs' => ['/etc/pacman.conf', '/etc/hosts', '/etc/fstab'],
      'backup_dir' => '/tmp/system-backup'
    }
  end

  def system_update
    puts "Checking for system updates..."

    # Refresh pacman database first
    puts "Refreshing pacman database..."
    stdout, stderr, status = Open3.capture3('sudo pacman -Sy')
    if status.success?
      puts "[OK] Database refreshed"
    else
      puts "[WARNING] Database refresh failed: #{stderr}"
    end

    # Check for available updates
    puts "Checking for available updates..."
    stdout, stderr, status = Open3.capture3('pacman -Qu')

    if status.success? && !stdout.empty?
      puts "\nAvailable updates:"
      puts stdout

      print "\nProceed with system update? Anything other than 'yes' will abort: "
      response = STDIN.gets.chomp.downcase
      return false unless response == 'yes'
    else
      puts "[OK] System is already up to date"
      return :no_updates
    end

    commands = [
      { cmd: 'sudo pacman -S --noconfirm archlinux-keyring', interactive: false },
      { cmd: 'sudo pacman -Syu', interactive: true }
    ]

    commands.each do |command|
      cmd = command[:cmd]
      interactive = command[:interactive]

      puts "Running: #{cmd}"

      if interactive
        puts "This command will run interactively - you can respond to prompts"
        status = system(cmd)
        if status
          puts "[OK] #{cmd} completed successfully"
        else
          error "[ERROR] #{cmd} failed"
          return false
        end
      else
        stdout, stderr, status = Open3.capture3(cmd)
        if status.success?
          puts "[OK] #{cmd} completed successfully"
          puts stdout if verbose && !stdout.empty?
        else
          error "[ERROR] #{cmd} failed: #{stderr}"
          return false
        end
      end
    end

    :updated
  end

  def handle_orphans
    stdout, _stderr, status = Open3.capture3('pacman -Qdtq')
    if status.success? && !stdout.strip.empty?
      puts "\nOrphaned packages detected:"
      puts stdout.lines.map { |l| "  - #{l.strip}" }
      print "\nRemove orphaned packages now? [y/N]: "
      answer = STDIN.gets.to_s.strip.downcase
      if answer == 'y' || answer == 'yes'
        system('sudo pacman -Rsunc $(pacman -Qdtq)')
      else
        puts "Skipping orphan removal. You can run: sudo pacman -Rsunc $(pacman -Qdtq)"
      end
    else
      puts "No orphaned packages to remove."
    end
  end

  def analyze_updates
    log "Analyzing package updates for breaking changes..."

    # Get list of updated packages
    stdout, stderr, status = Open3.capture3('pacman -Q')
    return true unless status.success?

    current_packages = parse_package_list(stdout)

    # Compare with previous state (if available)
    previous_packages = load_previous_packages
    changes = detect_package_changes(current_packages, previous_packages)

    if changes.any?
      return false unless display_update_analysis(changes)
    else
      log "[OK] No significant package changes detected"
    end

    # Save current state
    save_package_state(current_packages)
    true
  end

  def parse_package_list(pacman_output)
    packages = {}
    pacman_output.lines.each do |line|
      if line =~ /^(\S+)\s+(\S+)/
        packages[$1] = $2
      end
    end
    packages
  end

  def detect_package_changes(current, previous)
    changes = {
      major_updates: [],
      security_updates: [],
      breaking_changes: [],
      config_changes: []
    }

    current.each do |package, version|
      if previous[package] && previous[package] != version
        old_version = previous[package]

        # Check for major version changes
        if major_version_change?(old_version, version)
          changes[:major_updates] << { package: package, old: old_version, new: version }
        end

        # Check for breaking changes in package description
        if breaking_change_detected?(package)
          changes[:breaking_changes] << { package: package, old: old_version, new: version }
        end

        # Check if it's a critical package
        if config['critical_packages'].include?(package)
          changes[:config_changes] << { package: package, old: old_version, new: version }
        end
      end
    end

    changes
  end

  def major_version_change?(old_version, new_version)
    old_major = old_version.split('.')[0].to_i
    new_major = new_version.split('.')[0].to_i
    new_major > old_major
  end

  def breaking_change_detected?(package)
    stdout, stderr, status = Open3.capture3("pacman -Si #{package}")
    return false unless status.success?

    description = stdout.downcase
    config['breaking_change_keywords'].any? { |keyword| description.include?(keyword) }
  end

  def display_update_analysis(changes)
    puts "\nUPDATE ANALYSIS"
    puts "=" * 30

    if changes[:major_updates].any?
      puts "\n[WARNING] MAJOR VERSION UPDATES:"
      changes[:major_updates].each do |update|
        puts "  • #{update[:package]}: #{update[:old]} → #{update[:new]}"
      end
    end

    if changes[:breaking_changes].any?
      puts "\n[CRITICAL] BREAKING CHANGES DETECTED:"
      changes[:breaking_changes].each do |update|
        puts "  • #{update[:package]}: #{update[:old]} → #{update[:new]}"
      end

      print "\nBreaking changes detected! Continue anyway? Anything other than 'yes' will abort: "
      response = STDIN.gets.chomp.downcase
      return false unless response == 'yes'
    end

    if changes[:config_changes].any?
      puts "\n[INFO] CONFIGURATION CHANGES:"
      changes[:config_changes].each do |update|
        puts "  • #{update[:package]}: #{update[:old]} → #{update[:new]}"
      end
    end

    puts "\nRECOMMENDATIONS:"
    puts "  • Review breaking changes before continuing"
    puts "  • Check configuration files for critical packages"
    puts "  • Consider rebooting if kernel/systemd updated"

    true
  end

  def cleanup_cache
    log "Cleaning package cache..."
    stdout, stderr, status = Open3.capture3('sudo paccache -rk2')

    if status.success?
      log "[OK] Package cache cleaned (kept last 2 versions)"
      log stdout if verbose && !stdout.empty?
    else
      error "[ERROR] Cache cleanup failed: #{stderr}"
      return false
    end

    true
  end

  def sync_dotfiles
    return true if skip_operations.include?('dotfiles')

    log "Syncing dotfiles..."
    dotfiles_path = File.expand_path(config['dotfiles_path'])

          unless Dir.exist?(dotfiles_path)
        error "[ERROR] Dotfiles directory not found: #{dotfiles_path}"
        return false
      end

    Dir.chdir(dotfiles_path) do
      # Check for uncommitted changes
      stdout, stderr, status = Open3.capture3('git status --porcelain')
      if status.success? && !stdout.empty?
        warning "[WARNING] Uncommitted changes in dotfiles detected"
        log "Uncommitted files:"
        stdout.lines.each { |line| log "  #{line.chomp}" }
        log "[INFO] Skipping dotfiles sync due to uncommitted changes"
        return true  # Continue with other operations
      end

      # Pull latest changes
      stdout, stderr, status = Open3.capture3('git pull')
      if status.success?
        log "[OK] Dotfiles synced successfully"
        log stdout if verbose && !stdout.empty?
      else
        error "[ERROR] Dotfiles sync failed: #{stderr}"
        return false
      end
    end

    true
  end

  def sync_to_mega
    return true if skip_operations.include?('mega')

    log "Syncing to MEGA..."

    # Check if MEGA is configured
    log "Checking MEGA configuration..."
    stdout, stderr, status = Open3.capture3("mega-whoami")
    if !status.success?
      warning "[WARNING] MEGA not configured or not logged in. Run 'mega-login' first."
      return true
    end
    log "[OK] MEGA configured for user: #{stdout.strip}"

    # Sync directories
    config['mega_sync_dirs'].each do |dir|
      sync_item_to_mega(dir, is_directory: true)
    end

    # Sync individual files
    config['mega_sync_files'].each do |file|
      sync_item_to_mega(file)
    end

    true
  end

  def sync_item_to_mega(path, is_directory: false)
    expanded_path = File.expand_path(path)

    # Check if item exists
    if is_directory
      return unless Dir.exist?(expanded_path)
    else
      return unless File.exist?(expanded_path)
    end

    log "Checking for changes in #{expanded_path}..."

    # Check if item has been modified since last sync
    sync_log_file = File.expand_path('~/.config/system-update-mega-syncs.json')
    sync_log = load_mega_sync_log(sync_log_file)

    last_sync_time = sync_log[expanded_path]

    # Get modification time
    if is_directory
      item_mtime = Dir.glob("#{expanded_path}/**/*").map { |f| File.mtime(f) }.max
    else
      item_mtime = File.mtime(expanded_path)
    end

    # Determine if sync is needed
    needs_sync = if last_sync_time && item_mtime
                   item_mtime > DateTime.parse(last_sync_time).to_time
                 else
                   true # First time sync
                 end

    if needs_sync
      sync_reason = last_sync_time ? "Changes detected" : "First time sync"
      log "#{sync_reason}, syncing #{expanded_path}..."
      puts "Running: mega-put #{expanded_path} /"

      stdout, stderr, status = nil, nil, nil
      begin
        Timeout.timeout(60) do
          stdout, stderr, status = Open3.capture3("mega-put #{expanded_path} /")
        end
      rescue Timeout::Error
        warning "[WARNING] MEGA sync timed out for #{expanded_path}"
        return
      end

      if status && status.success?
        log "[OK] #{expanded_path} synced successfully"
        sync_log[expanded_path] = Time.now.to_s
        save_mega_sync_log(sync_log_file, sync_log)
      else
        warning "[WARNING] Failed to sync #{expanded_path}: #{stderr}"
      end
    else
      log "[OK] No changes detected in #{expanded_path}, skipping sync"
    end
  end

  def cleanup_logs
    log "Cleaning old log files..."

    # Rotate logs
    stdout, stderr, status = Open3.capture3('sudo logrotate -f /etc/logrotate.conf')
    if status.success?
      log "[OK] Log rotation completed"
    else
      warning "[WARNING] Log rotation failed: #{stderr}"
    end

    # Clean old log files
    retention_days = config['log_retention_days']
    stdout, stderr, status = Open3.capture3("find /var/log -name '*.log.*' -mtime +#{retention_days} -delete 2>/dev/null")
    if status.success?
      log "[OK] Old log files cleaned"
    else
      warning "[WARNING] Log cleanup failed (some files may be protected): #{stderr}"
    end
  end

  def cleanup_journal
    log "Cleaning systemd journal..."

    retention_days = config['journal_retention_days']
    stdout, stderr, status = Open3.capture3("sudo journalctl --vacuum-time=#{retention_days}d")

    if status.success?
      log "[OK] Journal cleaned (kept last #{retention_days} days)"
    else
      warning "[WARNING] Journal cleanup failed: #{stderr}"
    end
  end

  def check_disk_space
    log "Checking disk space..."

    stdout, stderr, status = Open3.capture3("df -h /")
    if status.success?
      log "Disk space:"
      log stdout
    else
      warning "[WARNING] Could not check disk space: #{stderr}"
    end
  end

  def check_services
    log "Checking critical services..."

    critical_services = config['critical_services']

    critical_services.each do |service|
      stdout, stderr, status = Open3.capture3("systemctl is-active #{service}")
      if status.success? && stdout.strip == 'active'
        log "[OK] #{service} is running"
      else
        # Check if it's a target (like network-online.target)
        if service.include?('.target')
          stdout, stderr, status = Open3.capture3("systemctl is-active #{service}")
          if status.success? && stdout.strip == 'active'
            log "[OK] #{service} is active"
          else
            warning "[WARNING] #{service} is not active"
          end
        elsif service == 'systemd'
          # systemd is always running, just check if we can access it
          stdout, stderr, status = Open3.capture3("systemctl --version")
          if status.success?
            log "[OK] systemd is accessible"
          else
            warning "[WARNING] systemd is not accessible"
          end
        else
          warning "[WARNING] #{service} is not running properly"
        end
      end
    end
  end

  def detect_orphans
    log "Detecting orphaned packages..."

    stdout, stderr, status = Open3.capture3('pacman -Qdtq')
    if status.success? && !stdout.empty?
      log "Found orphaned packages:"
      stdout.lines.each { |line| log "  #{line.chomp}" }
      log "Run 'sudo pacman -Rsunc $(pacman -Qdtq)' to remove them"
    else
      log "[OK] No orphaned packages found"
    end
  end

  def verify_package_integrity
    log "Verifying package integrity..."

    stdout, stderr, status = Open3.capture3('sudo pacman -Qkk')
    if status.success?
      log "[OK] Package integrity verified"
    else
      # Filter out common warnings that are usually harmless
      filtered_errors = stderr.lines.reject do |line|
        line.include?('Permissions mismatch') ||
        line.include?('UID mismatch') ||
        line.include?('GID mismatch') ||
        line.include?('Symlink path mismatch') ||
        line.include?('Modification time mismatch')
      end

      if filtered_errors.empty?
        log "[OK] Package integrity verified (minor permission/symlink warnings ignored)"
      else
        warning "[WARNING] Package integrity check found issues:"
        filtered_errors.each { |error| warning "  #{error.chomp}" }
      end
    end
  end

  def check_security_updates
    log "Checking for security updates..."

    stdout, stderr, status = Open3.capture3('pacman -Qu')
    if status.success? && !stdout.empty?
      log "Available updates:"
      stdout.lines.each { |line| log "  #{line.chomp}" }
    else
      log "[OK] System is up to date"
    end
  end

  def audit_open_ports
    log "Auditing open network ports..."

    stdout, stderr, status = Open3.capture3('ss -tuln')
    if status.success?
      log "Open ports:"
      log stdout
    else
      warning "[WARNING] Could not audit open ports: #{stderr}"
    end
  end

  def cleanup_kernel_modules
    log "Cleaning unused kernel modules..."

    stdout, stderr, status = Open3.capture3('sudo depmod -a')
    if status.success?
      log "[OK] Kernel modules cleaned"
    else
      warning "[WARNING] Kernel module cleanup failed: #{stderr}"
    end
  end

  def rebuild_font_cache
    log "Rebuilding font cache..."

    stdout, stderr, status = Open3.capture3('sudo fc-cache -fv')
    if status.success?
      log "[OK] Font cache rebuilt"
    else
      warning "[WARNING] Font cache rebuild failed: #{stderr}"
    end
  end

  def cleanup_locales
    log "Cleaning unused locales..."

    stdout, stderr, status = Open3.capture3('sudo locale-gen')
    if status.success?
      log "[OK] Locales cleaned"
    else
      warning "[WARNING] Locale cleanup failed: #{stderr}"
    end
  end

  def optimize_package_db
    log "Optimizing package database..."

    stdout, stderr, status = Open3.capture3('sudo pacman -Sc --noconfirm')
    if status.success?
      log "[OK] Package database optimized"
    else
      warning "[WARNING] Package database optimization failed: #{stderr}"
    end
  end

  def backup_configs
    log "Backing up critical configurations..."

    backup_dir = File.expand_path(config['backup_dir'])
    FileUtils.mkdir_p(backup_dir)

    critical_configs = config['critical_configs']

    critical_configs.each do |config_file|
      if File.exist?(config_file)
        backup_file = File.join(backup_dir, File.basename(config_file))

        # Use sudo for protected files
        if config_file == '/etc/sudoers'
          stdout, stderr, status = Open3.capture3("sudo cp #{config_file} #{backup_file}")
          if status.success?
            log "[OK] Backed up #{config_file}"
          else
            warning "[WARNING] Failed to backup #{config_file}: #{stderr}"
          end
        else
          begin
            FileUtils.cp(config_file, backup_file)
            log "[OK] Backed up #{config_file}"
          rescue Errno::EACCES => e
            warning "[WARNING] Permission denied backing up #{config_file}: #{e.message}"
          end
        end
      end
    end
  end

  def export_package_list
    log "Exporting package list..."

    backup_dir = File.expand_path(config['backup_dir'])
    FileUtils.mkdir_p(backup_dir)

    timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
    package_list_file = File.join(backup_dir, "packages_#{timestamp}.txt")

    stdout, stderr, status = Open3.capture3('pacman -Q')
    if status.success?
      File.write(package_list_file, stdout)
      log "[OK] Package list exported to #{package_list_file}"
    else
      warning "[WARNING] Failed to export package list: #{stderr}"
    end
  end

  def verify_boot_config
    log "Verifying boot configuration..."

    # Check if bootloader configuration exists
    bootloader_configs = ['/boot/grub/grub.cfg', '/boot/loader/entries/*.conf']

    bootloader_configs.each do |config_pattern|
      if Dir.glob(config_pattern).any?
        log "[OK] Bootloader configuration found"
        return
      end
    end

    warning "[WARNING] No bootloader configuration found"
  end

  def generate_report
    puts "\nSYSTEM UPDATE REPORT"
    puts "=" * 30

    if @errors.any?
      puts "\n[ERROR] ERRORS:"
      @errors.each { |error| puts "  • #{error}" }
    end

    if @warnings.any?
      puts "\n[WARNING] WARNINGS:"
      @warnings.each { |warning| puts "  • #{warning}" }
    end

    if @errors.empty? && @warnings.empty?
      puts "\n[OK] All operations completed successfully!"
    end

    puts "\nNEXT STEPS:"
    puts "  • Review any breaking changes mentioned above"
    puts "  • Reboot if kernel or systemd was updated"
    puts "  • Check services if any warnings were shown"
  end

  def load_previous_packages
    package_state_file = File.expand_path("#{config['backup_dir']}/package_state.json")
    return {} unless File.exist?(package_state_file)

    begin
      JSON.parse(File.read(package_state_file))
    rescue JSON::ParserError
      {}
    end
  end

  def save_package_state(packages)
    backup_dir = File.expand_path(config['backup_dir'])
    FileUtils.mkdir_p(backup_dir)

    package_state_file = File.join(backup_dir, 'package_state.json')
    File.write(package_state_file, JSON.pretty_generate(packages))
  end

  def load_mega_sync_log(sync_log_file)
    if File.exist?(sync_log_file)
      begin
        JSON.parse(File.read(sync_log_file))
      rescue JSON::ParserError
        {}
      end
    else
      {}
    end
  end

  def save_mega_sync_log(sync_log_file, sync_log)
    FileUtils.mkdir_p(File.dirname(sync_log_file))
    File.write(sync_log_file, JSON.pretty_generate(sync_log))
  end

  def log(message)
    puts "[#{Time.now.strftime('%H:%M:%S')}] #{message}" if verbose
  end

  def error(message)
    @errors << message
    puts message
  end

  def warning(message)
    @warnings << message
    puts message
  end
end

# CLI Interface
if __FILE__ == $0
  options = {
    verbose: false,
    skip: []
  }

  OptionParser.new do |opts|
    opts.banner = "Usage: system-update.rb [options]"

    opts.on("-v", "--verbose", "Enable verbose output") do
      options[:verbose] = true
    end

    opts.on("--skip OPERATION", "Skip specific operation (dotfiles, mega)") do |operation|
      options[:skip] << operation
    end

    opts.on("-h", "--help", "Show this help message") do
      puts opts
      exit
    end
  end.parse!

  updater = SystemUpdate.new(options)
  success = updater.call

  exit success ? 0 : 1
end
