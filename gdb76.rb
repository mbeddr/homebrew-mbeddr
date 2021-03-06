require "formula"

class UniversalBrewedPython < Requirement
  satisfy { archs_for_command("python").universal? }

  def message; <<-EOS.undent
    A build of GDB using a brewed Python was requested, but Python is not
    a universal build.
    GDB requires Python to be built as a universal binary or it will fail
    if attempting to debug a 32-bit binary on a 64-bit host.
    EOS
  end
end

class Gdb76 < Formula
  homepage "http://www.gnu.org/software/gdb/"
  url "http://ftpmirror.gnu.org/gdb/gdb-7.6.2.tar.gz"
  mirror "http://ftp.gnu.org/gnu/gdb/gdb-7.6.2.tar.gz"
  sha256 "17f7bcda1b24336aadcb1c5e703c355551e59467e221c6f4353b720dffad73a7"

  depends_on "pkg-config" => :build
  depends_on "readline"
  depends_on "xz"
  depends_on "guile" => :optional

  if build.with? "brewed-python"
    depends_on UniversalBrewedPython
  end

  option "with-brewed-python", "Use the Homebrew version of Python"
  option "with-all-targets", "Build with support for all targets"

  # Fix compilation on 10.10
  # https://sourceware.org/bugzilla/show_bug.cgi?id=17046
  # https://sourceware.org/ml/gdb-patches/2014-09/msg00510.html
  patch :DATA

  def install
    args = [
      "--prefix=#{prefix}",
      "--disable-debug",
      "--disable-dependency-tracking",
      "--with-system-readline",
      "--with-lzma"
    ]

    args << "--with-guile" if build.with? "guile"
    args << "--enable-targets=all" if build.with? "all-targets"

    if build.with? "brewed-python"
      args << "--with-python=#{HOMEBREW_PREFIX}"
    else
      args << "--with-python=/usr"
    end


  #args << "--program-suffix=-#{version.to_s.slice(/^\d/)}"


    system "./configure", *args
    system "make"
    system "make", "install"

    # Remove conflicting items with binutils
    rm_rf include
    rm_rf lib
    rm_rf share/"locale"
    rm_rf share/"info"
  end

  def caveats; <<-EOS.undent
    gdb requires special privileges to access Mach ports.
    You will need to codesign the binary. For instructions, see:
      http://sourceware.org/gdb/wiki/BuildingOnDarwin
    
    On 10.12 (Sierra) or later with SIP, you need to run this:

      echo "set startup-with-shell off" >> ~/.gdbinit
    EOS
  end
end

__END__
diff --git a/gdb/darwin-nat.c b/gdb/darwin-nat.c
index 5714288..38f768f 100644
--- a/gdb/darwin-nat.c
+++ b/gdb/darwin-nat.c
@@ -42,7 +42,7 @@
 
 #include <sys/ptrace.h>
 #include <sys/signal.h>
-#include <machine/setjmp.h>
+#include <setjmp.h>
 #include <sys/types.h>
 #include <unistd.h>
 #include <signal.h>
