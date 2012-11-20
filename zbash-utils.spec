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

* Tue Nov 20 2012 Laird Breyer <laird@zomojo.com>
- Added --random-nice option to zsandbox
* Thu Nov 8 2012 Laird Breyer <laird@zomojo.com>
- Added zsandbox and man pages
* Mon Nov 5 2012 Laird Breyer <laird@zomojo.com>
- Initial package contains zoptparse.sh
