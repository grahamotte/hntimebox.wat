module Patches
  class DeploymentUser < Base
    class << self
      def needed?
        !!nofail { run_remote_root('ls -lah') }
      end

      def apply
        # sudo user
        run_remote_root("useradd #{remote_user} -m -G wheel")
        run_remote_root("yes #{remote_pass} | passwd #{remote_user}")
        run_remote_root("echo '#{remote_user} ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers")

        # keyfile
        run_remote_root("cp -r ~/.ssh /home/#{remote_user}/")
        write_file_root("/home/#{remote_user}/.ssh/id_rsa", Secrets.id_rsa)
        run_remote_root("chmod 400 /home/#{remote_user}/.ssh/id_rsa")
        write_file_root("/home/#{remote_user}/.ssh/id_rsa.pub", Secrets.id_rsa_pub)
        run_remote_root("chmod 400 /home/#{remote_user}/.ssh/id_rsa.pub")
        run_remote_root("chown -R #{remote_user}:#{remote_user} /home/#{remote_user}/")

        # lockout root user
        write_file_root('/etc/ssh/sshd_config', sshd_conf)
        run_remote_root('systemctl restart sshd.service')

        # allow loopback requests
        run_remote("sed -i -e '$a\\' ~/.ssh/authorized_keys")
        run_remote('cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys')
      end

      # ---

      def run_remote_root(cmd, *opts, just_status: false)
        run(cmd, *opts, user: 'root', host: ipv4, just_status: just_status)
      end

      def write_file_root(path, data)
        local_tmp_file = File.expand_path(File.join(local_dir, 'tmp', 'file_to_upload'))
        remote_tmp_file = '/tmp/root_uploaded_file'

        File.open(local_tmp_file, 'w+') { |f| f << data; f << "\n" }
        run_local("scp -i #{Secrets.id_rsa_path} #{local_tmp_file} root@#{ipv4}:#{remote_tmp_file}")
        run_remote_root("cp #{remote_tmp_file} #{path}")
      end

      def sshd_conf
        <<~TEXT
          PermitRootLogin no
          AuthorizedKeysFile .ssh/authorized_keys
          PasswordAuthentication no
          ChallengeResponseAuthentication no
          UsePAM yes
          PrintMotd no
          Subsystem sftp /usr/lib/ssh/sftp-server
        TEXT
      end
    end
  end
end
