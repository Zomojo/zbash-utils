Summary: Zomojo Bash Scripts Package
Name: zbash_utils
Version: %{version_base}
Release: %{version_release}%{org_tag}%{dist}
License: Copyright Zomojo Pty. Ltd.
Group: System/Libraries
Source: %{name}-%{version}.tgz
Buildroot: %_tmppath/%{name}-%{version}
Prefix: /usr
BuildArch: noarch

%description
zbash-utils provides useful functions for bash shell scripts.

%prep
%setup

%build
test %{buildroot} != "/" && rm -rf %{buildroot}

%install
mkdir -p %{buildroot}/usr/bin

find -name ".svn" | xargs rm -rf 

# install bin components
cp -rf --no-dereference scripts/* %{buildroot}/usr/bin
chmod -R 755 %{buildroot}/usr/bin

%clean
test "%{buildroot}" != "/" && rm -rf %{buildroot}

%files
%defattr(-,root,root)
%{_bindir}/*


%changelog

* Mon Nov 5 2012 Laird Breyer <laird@zomojo.com>
- Initial package contains zoptparse.sh
