all: \
	frida-python \
	frida-npapi

include common.mk

distclean:
	rm -rf build/

clean:
	rm -f build/*.rc
	rm -f build/*.site
	rm -f build/*-stamp
	rm -rf build/frida-linux-x86_64
	rm -rf build/frida-linux-x86_64-stripped
	rm -rf build/tmp-linux-x86_64
	rm -rf build/tmp-linux-x86_64-stripped
	cd udis86 && git clean -xfd
	cd frida-gum && git clean -xfd
	cd frida-core && git clean -xfd
	cd frida-python && git clean -xfd
	cd frida-npapi && git clean -xfd

check: check-gum check-core


udis86: \
	build/frida-linux-x86_64/lib/pkgconfig/udis86.pc

udis86/configure: build/frida-env-linux-x86_64.rc udis86/configure.ac
	. build/frida-env-linux-x86_64.rc && cd udis86 && ./autogen.sh

build/tmp-%/udis86/Makefile: build/frida-env-%.rc udis86/configure
	mkdir -p $(@D)
	. build/frida-env-$*.rc && cd $(@D) && ../../../udis86/configure

build/frida-%/lib/pkgconfig/udis86.pc: build/tmp-%/udis86/Makefile build/udis86-submodule-stamp
	. build/frida-env-$*.rc && make -C build/tmp-$*/udis86 install
	@touch -c $@


frida-gum: \
	build/frida-linux-x86_64/lib/pkgconfig/frida-gum-1.0.pc

frida-gum/configure: build/frida-env-linux-x86_64.rc frida-gum/configure.ac
	. build/frida-env-linux-x86_64.rc && cd frida-gum && ./autogen.sh

build/tmp-%/frida-gum/Makefile: build/frida-env-%.rc frida-gum/configure build/frida-%/lib/pkgconfig/udis86.pc
	mkdir -p $(@D)
	. build/frida-env-$*.rc && cd $(@D) && ../../../frida-gum/configure

build/frida-%/lib/pkgconfig/frida-gum-1.0.pc: build/tmp-%/frida-gum/Makefile build/frida-gum-submodule-stamp
	@touch -c build/tmp-$*/frida-gum/gum/libfrida_gum_la-gum.lo
	. build/frida-env-$*.rc && make -C build/tmp-$*/frida-gum install
	@touch -c $@

check-gum: check-gum-linux-x86_64
check-gum-linux-x86_64: build/frida-linux-x86_64/lib/pkgconfig/frida-gum-1.0.pc
	build/tmp-linux-x86_64/frida-gum/tests/gum-tests


frida-core: \
	build/frida-linux-x86_64/lib/pkgconfig/frida-core-1.0.pc

frida-core/configure: build/frida-env-linux-x86_64.rc frida-core/configure.ac
	. build/frida-env-linux-x86_64.rc && cd frida-core && ./autogen.sh

build/tmp-%/frida-core/Makefile: build/frida-env-%.rc frida-core/configure build/frida-%/lib/pkgconfig/frida-gum-1.0.pc
	mkdir -p $(@D)
	. build/frida-env-$*.rc && cd $(@D) && ../../../frida-core/configure

build/tmp-%/frida-core/tools/resource-compiler: build/tmp-%/frida-core/Makefile build/frida-core-submodule-stamp
	@touch -c build/tmp-$*/frida-core/tools/frida_resource_compiler-resource-compiler.o
	. build/frida-env-$*.rc && make -C build/tmp-$*/frida-core/tools
	@touch -c $@

build/tmp-%/frida-core/lib/agent/libfrida-agent.la: build/tmp-%/frida-core/Makefile build/frida-core-submodule-stamp
	@touch -c build/tmp-$*/frida-core/lib/agent/libfrida_agent_la-agent.lo
	. build/frida-env-$*.rc && make -C build/tmp-$*/frida-core/lib
	@touch -c $@

build/tmp-%-stripped/frida-core/lib/agent/.libs/libfrida-agent.so: build/tmp-%/frida-core/lib/agent/libfrida-agent.la
	mkdir -p $(@D)
	cp build/tmp-$*/frida-core/lib/agent/.libs/libfrida-agent.so $@
	strip --strip-all $@

build/frida-%/lib/pkgconfig/frida-core-1.0.pc: build/tmp-%-stripped/frida-core/lib/agent/.libs/libfrida-agent.so build/tmp-%/frida-core/tools/resource-compiler
	@touch -c build/tmp-$*/frida-core/src/libfrida_core_la-frida.lo
	. build/frida-env-$*.rc \
		&& cd build/tmp-$*/frida-core \
		&& make -C src install \
			AGENT=../../../../build/tmp-$*-stripped/frida-core/lib/agent/.libs/libfrida-agent.so \
		&& make install-data-am
	@touch -c $@

build/tmp-%/frida-core/tests/frida-tests: build/frida-%/lib/pkgconfig/frida-core-1.0.pc
	@touch -c build/tmp-$*/frida-core/tests/main.o
	@touch -c build/tmp-$*/frida-core/tests/inject-victim.o
	@touch -c build/tmp-$*/frida-core/tests/inject-attacker.o
	. build/frida-env-$*.rc && make -C build/tmp-$*/frida-core/tests
	@touch -c $@

check-core: check-core-linux-x86_64
check-core-linux-x86_64: build/tmp-linux-x86_64/frida-core/tests/frida-tests
	$<


frida-python: \
	build/frida-linux-x86_64-stripped/lib/python2.7/site-packages/frida.py \
	build/frida-linux-x86_64-stripped/lib/python2.7/site-packages/_frida.so

frida-python/configure: build/frida-env-linux-x86_64.rc frida-python/configure.ac
	. build/frida-env-linux-x86_64.rc && cd frida-python && ./autogen.sh

build/tmp-%/frida-python2.7/Makefile: build/frida-env-%.rc frida-python/configure build/frida-%/lib/pkgconfig/frida-core-1.0.pc
	mkdir -p $(@D)
	. build/frida-env-$*.rc && cd $(@D) && PYTHON=/usr/bin/python2.7 ../../../frida-python/configure

build/tmp-%/frida-python2.7/src/_frida.la: build/tmp-%/frida-python2.7/Makefile build/frida-python-submodule-stamp
	@touch -c build/tmp-$*/frida-python2.7/src/_frida.lo
	. build/frida-env-$*.rc && cd build/tmp-$*/frida-python2.7 && make install
	@touch -c $@

build/frida-%-stripped/lib/python2.7/site-packages/frida.py: build/tmp-linux-x86_64/frida-python2.7/src/_frida.la
	mkdir -p $(@D)
	cp -a build/frida-$*/lib/python2.7/site-packages/frida.py $@
	@touch $@

build/frida-%-stripped/lib/python2.7/site-packages/_frida.so: build/tmp-linux-x86_64/frida-python2.7/src/_frida.la
	mkdir -p $(@D)
	cp build/tmp-$*/frida-python2.7/src/.libs/_frida.so $@
	strip --strip-all $@


frida-npapi: \
	build/frida-linux-x86_64-stripped/lib/browser/plugins/libnpfrida.so

frida-npapi/configure: build/frida-env-linux-x86_64.rc frida-npapi/configure.ac
	. build/frida-env-linux-x86_64.rc && cd frida-npapi && ./autogen.sh

build/tmp-%/frida-npapi/Makefile: build/frida-env-%.rc frida-npapi/configure build/frida-%/lib/pkgconfig/frida-core-1.0.pc
	mkdir -p $(@D)
	. build/frida-env-$*.rc && cd $(@D) && ../../../frida-npapi/configure

build/tmp-%/frida-npapi/src/libnpfrida.la: build/tmp-%/frida-npapi/Makefile build/frida-npapi-submodule-stamp
	@touch -c build/tmp-$*/frida-npapi/src/npfrida-plugin.lo
	. build/frida-env-$*.rc && cd build/tmp-$*/frida-npapi && make install
	@touch -c $@

build/frida-%-stripped/lib/browser/plugins/libnpfrida.so: build/tmp-%/frida-npapi/src/libnpfrida.la
	mkdir -p $(@D)
	cp build/tmp-$*/frida-npapi/src/.libs/libnpfrida.so $@
	strip --strip-all $@


.PHONY: \
	distclean clean check git-submodules git-submodule-stamps \
	udis86 udis86-update-submodule-stamp \
	frida-gum frida-gum-update-submodule-stamp check-gum check-gum-linux-x86_64 \
	frida-core frida-core-update-submodule-stamp check-core check-core-linux-x86_64 \
	frida-python frida-python-update-submodule-stamp \
	frida-npapi frida-npapi-update-submodule-stamp
.SECONDARY:
