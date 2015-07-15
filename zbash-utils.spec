Summary: Zomojo Bash Scripts Package
Name: zbash-utils
Version: %{version_base}
Release: %{version_release}%{org_tag}%{dist}
License: Copyright Zomojo Pty. Ltd.
Group: System/Libraries
Source: %{name}-%{version}.tgz
Buildroot: %_tmppath/%{name}-%{version}
Prefix: /usr
BuildArch: noarch
BuildRequires: perl-podlators

%description
zbash-utils provides useful functions for bash shell scripts.

%prep
%setup

%build
cd %projectdir
test %{buildroot} != "/" && rm -rf %{buildroot}

%install
cd %projectdir
mkdir -p %{buildroot}/usr/bin

# install bin components
cp -f --no-dereference scripts/* %{buildroot}/usr/bin

# make man pages
mkdir -p %{buildroot}/usr/share/man/man1
for f in scripts/* ; do
    f1=`basename $f`.1
    pod2man --center=zbash-utils --release=zbash-utils $f > %{buildroot}/usr/share/man/man1/$f1       
done

%clean
test "%{buildroot}" != "/" && rm -rf %{buildroot}

%files
%defattr(-,root,root)
/usr/bin/*

%doc
/usr/share/man/man1/*

%changelog
* Mon May 12 2014 Laird Breyer <laird@zomojo.com>
- if $TMPDIR is nonzero, use it as prefix for tempfiles, else use /tmp
* Wed Apr 30 2014 Laird Breyer <laird@zomojo.com>
- correct parsing of options containing equal signs
* Tue Dec 30 2013 Laird Breyer <laird@zomojo.com>
- longer error messages in zsandbox
* Tue Dec 17 2013 Laird Breyer <laird@zomojo.com>
- changes to zsandbox implementation
* Tue Nov 26 2013 Laird Breyer <laird@zomojo.com>
- Added zrecord function 
* Fri Nov 22 2013 Laird Breyer <laird@zomojo.com>
- Added zerror, which is like zmessage but returns 1 (for exiting scripts)
* Thu Sep 19 2013 Laird Breyer <laird@zomojo.com>
- Added ztempfile and ztempdir commands, also child process cleanup
* Fri Jan 1 2013 Laird Breyer <laird@zomojo.com>
- Added --use-dir to zsandbox
* Thu Dec 6 2012 Laird Breyer <laird@zomojo.com>
- Added exception handling in zoptparse.sh
* Tue Dec 4 2012 Laird Breyer <laird@zomojo.com>
- Added strict options checking in zoptparse.sh
* Tue Nov 20 2012 Laird Breyer <laird@zomojo.com>
- Added --random-nice option to zsandbox
* Thu Nov 8 2012 Laird Breyer <laird@zomojo.com>
- Added zsandbox and man pages
* Mon Nov 5 2012 Laird Breyer <laird@zomojo.com>
- Initial package contains zoptparse.sh
