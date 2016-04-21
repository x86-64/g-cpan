t=../t
share=../share

99ls-la.txt:
	rsync -Pna cpan-rsync.perl.org::CPAN --list-only 2>&1 >$@

02packages.details.txt:
	wget http://cpan.nctu.edu.tw/modules/02packages.details.txt -O $@ 

21versions=$(t)/21versions.txt
$(21versions): packages
	cat $< | cut -d\  -f2 > $@

22versiongentoo=$(t)/22versiongentoo.yaml
$(22versiongentoo): packages
	./22versiongentoo.pl $< $@

version_rules=$(share)/version_rules.yaml
$(version_rules): $(22versiongentoo)
	./version_rules.pl $< $@

package_authors=$(share)/package_authors.yaml
$(package_authors): 02packages.details.txt
	./package_authors.pl $< $@

packages: 99ls-la.txt $(package_authors)
	./packages.pl $< > $@.tmp
	mv $@.tmp $@

official_ebuilds=official_ebuilds.yaml
$(official_ebuilds):
	./official_ebuilds.pl $@

package_rules=$(share)/package_rules.yaml
$(package_rules): $(official_ebuilds)
	./package_rules.pl $< $@

inputs=99ls-la.txt 02packages.details.txt $(official_ebuilds)
files=$(21versions) $(22versiongentoo) $(version_rules) $(package_authors)
all: $(files) 
clean:
	rm $(files) 2>&1 >/dev/null || true

clean-everything:
	rm $(files) $(inputs) 2>&1 >/dev/null || true
