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

%description
zbash-utils provides useful functions for bash shell scripts.

%prep
%setup

%build
test %{buildroot} != "/" && rm -rf %{buildroot}

%install
mkdir -p %{buildroot}/usr/bin

# install bin components
cp -f --no-dereference scripts/* %{buildroot}/usr/bin

%clean
test "%{buildroot}" != "/" && rm -rf %{buildroot}

%files
%defattr(-,root,root)
/usr/bin/*


%changelog

* Mon Nov 5 2012 Laird Breyer <laird@zomojo.com>
- Initial package contains zoptparse.sh
