.PHONY: clean-pyc clean-build docs clean activate-venv
define BROWSER_PYSCRIPT
import os, webbrowser, sys
try:
	from urllib import pathname2url
except:
	from urllib.request import pathname2url

webbrowser.open("file://" + pathname2url(os.path.abspath(sys.argv[1])))
endef
export BROWSER_PYSCRIPT
BROWSER := python -c "$$BROWSER_PYSCRIPT"

help:
	@echo "clean - remove all build, test, coverage and Python artifacts"
	@echo "clean-build - remove build artifacts"
	@echo "clean-pyc - remove Python file artifacts"
	@echo "clean-test - remove test and coverage artifacts"
	@echo "lint - check style with flake8"
	@echo "test - run tests quickly with the default Python"
	@echo "test-all - run tests on every Python version with tox"
	@echo "coverage - check code coverage quickly with the default Python"
	@echo "docs - generate Sphinx HTML documentation, including API docs"
	@echo "release - package and upload a release"
	@echo "dist - package"
	@echo "install - install the package to the active Python's site-packages"

clean: clean-build clean-pyc clean-test

clean-build:
	rm -fr python
	rm -fr *.zip
	rm -fr build/
	rm -fr dist/
	rm -fr .eggs/
	find . -name '*.egg-info' -exec rm -fr {} +
	find . -name '*.egg' -exec rm -fr {} +

clean-pyc:
	find . -name '*.pyc' -exec rm -f {} +
	find . -name '*.pyo' -exec rm -f {} +
	find . -name '*~' -exec rm -f {} +
	find . -name '__pycache__' -exec rm -fr {} +

clean-test:
	rm -fr .tox/
	rm -f .coverage
	rm -fr htmlcov/

lint:
	flake8 protein_design_eval tests

test:
	python setup.py test

test-all:
	tox

coverage:
	coverage run --source protein_design_eval setup.py test
	coverage report -m
	coverage html
	$(BROWSER) htmlcov/index.html

docs:
	rm -f docs/protein_design_eval.rst
	rm -f docs/modules.rst
	sphinx-apidoc -o docs/ protein_design_eval
	$(MAKE) -C docs clean
	$(MAKE) -C docs html
	$(BROWSER) docs/_build/html/index.html

servedocs: docs
	watchmedo shell-command -p '*.rst' -c '$(MAKE) -C docs html' -R -D .

release: clean
	python setup.py sdist upload
	python setup.py bdist_wheel upload

dist: clean
	python setup.py sdist
	python setup.py bdist_wheel
	ls -l dist

install: clean
	python setup.py install

dataflow-venv:
	python3.6 -m venv dataflow_venv

venv:
	python3 -m venv venv

requirements: requirements.txt requirements/prod.txt
	pip install --upgrade pip
	pip install wheel
	pip install -r requirements/prod.txt

requirements-dev: requirements requirements/prod.txt requirements/dev.txt
	pip install --upgrade pip
	pip install wheel
	pip install -r requirements/dev.txt

requirements-dataflow: dataflow_venv requirements/dataflow.txt
	dataflow_venv/bin/pip install --upgrade pip
	dataflow_venv/bin/pip install wheel
	dataflow_venv/bin/pip install -r requirements/dataflow.txt

dataflow-archive: requirements/dataflow.txt dataflow-venv requirements-dataflow
	mkdir python
	cp -r dataflow_venv/lib python/lib
	cp -r dataflow_venv/bin python/bin
	rm -fr python/bin/pip*
	rm -fr python/bin/python*
	rm -fr python/bin/activate*
	cp -r /opt/dataflow/java java
	zip -r archive.zip python java
	rm -rf python java