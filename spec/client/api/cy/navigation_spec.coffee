describe "$Cypress.Cy Navigation Commands", ->
  enterCommandTestingMode()

  context "#visit", ->
    it "resolves the subject to the remote iframe window", ->
      @cy.visit("/foo").then (win) ->
        expect(win).to.eq $("iframe").prop("contentWindow")

    it "changes the src of the iframe to the initial src", ->
      @cy.visit("/foo").then ->
        src = $("iframe").attr("src")
        expect(src).to.eq "/foo"

    it "immediately updates the stored href on load", (done) ->
      _storeHref = @sandbox.spy @cy, "_storeHref"

      @cy.on "invoke:subject", (subject, obj) ->
        expect(_storeHref.callCount).to.eq 2
        done()

      @cy.visit("/foo")

    it "prevents _hrefChanged from always being true after visiting", (done) ->
      @cy.on "invoke:subject", (subject, obj) ->
        expect(@_hrefChanged()).to.be.false
        done()

      @cy.visit("/foo")

    it "rejects the promise if data-cypress-visit-error is in the body"

    it "rejects with error: ...something..."

    it "extends the runnables timeout before visit"

    it "resets the runnables timeout after visit"

    it "invokes onLoad callback"

    it "invokes onBeforeLoad callback", (done) ->
      @cy.visit("fixtures/html/sinon.html", {
        onBeforeLoad: (contentWindow) ->
          expect(contentWindow.sinon).to.be.defined
          done()
      })

    it "does not error without an onBeforeLoad callback", ->
      @cy.visit("fixtures/html/sinon.html").then ->
        prev = @cy.prop("current").prev
        expect(prev.args).to.have.length(1)

    it "first navigates to about:blank if existing url isnt about:blank", ->
      cy
        .window().as("win")
        .visit("timeout?ms=0").then ->
          @_href = @sandbox.spy @cy, "_href"
        .visit("timeout?ms=1").then ->
          expect(@_href).to.be.calledWith @win, "about:blank"

    it "does not navigate to about:blank if existing url is about:blank", ->
      @sandbox.stub(@cy.sync, "url").returns("about:blank")
      _href = @sandbox.spy @cy, "_href"

      cy
        .visit("timeout?ms=0").then ->
          expect(_href).not.to.be.called

    describe "location getter overrides", ->
      beforeEach ->
        @eq = (attr, str) =>
          expect(@win.location[attr]).to.eq str

        @cy
          .visit("fixtures/html/sinon.html?foo=bar#dashboard?baz=quux")
          .window().as("win").then (win) ->
            ## ensure href always returns the full path
            ## so our tests guarantee that in fact we are
            ## overriding the location getters
            expect(win.location.href).to.include "fixtures/html/sinon.html?foo=bar#dashboard?baz=quux"

      it "hash", ->
        @eq "hash", "#dashboard?baz=quux"

      it "hostname", ->
        @eq "hostname", "localhost"

      it "origin", ->
        @eq "origin", "http://localhost:3500"

      it "pathname", ->
        @eq "pathname", "/fixtures/html/sinon.html"

      it "port", ->
        @eq "port", "3500"

      it "protocol", ->
        @eq "protocol", "http:"

      it "search", ->
        @eq "search", "?foo=bar"

    describe "history method overrides", ->
      beforeEach ->
        @cy
          .visit("fixtures/html/sinon.html")
          .window().as("win")
          .then ->
            @urlChanged = @sandbox.spy @cy, "urlChanged"

      _.each ["back", "forward", "go"], (attr) =>
        it "fires 'history:event' on attr: '#{attr}'", ->
          if attr is "go"
            arg = -1

          @win.history[attr](arg)
          expect(@urlChanged).to.be.called

      _.each ["pushState", "replaceState"], (attr) =>
        it "fires 'history:event' on attr: '#{attr}'", ->
          @win.history[attr]({}, "foo")
          expect(@urlChanged).to.be.called

    describe ".log", ->
      beforeEach ->
        @Cypress.on "log", (@log) =>

      it "logs immediately before resolving", (done) ->
        @Cypress.on "log", (log) ->
          expect(log.pick("name", "message")).to.deep.eq {
            name: "visit"
            message: "localhost:4200/app/foo#/hash"
          }

        @cy.visit("localhost:4200/app/foo#/hash").then -> done()

      it "logs obj once complete", ->
        @cy.visit("index.html").then ->
          obj = {
            state: "success"
            name: "visit"
            message: "index.html"
          }

          _.each obj, (value, key) =>
            expect(@log.get(key)).deep.eq(value, "expected key: #{key} to eq value: #{value}")

      it "can turn off logging", ->
        log = null

        @Cypress.on "log", (l) ->
          log = l

        @cy.visit("timeout?ms=0", {log: false}).then ->
          expect(log).to.be.null

    describe "errors", ->
      beforeEach ->
        @allowErrors()

        @failVisit = =>
          cy$ = @cy.$

          ## act as if we have this node
          error = @sandbox.stub @cy, "$", (selector) ->
            if selector is "[data-cypress-visit-error]"
              error.restore()
              return {length: 1}
            else
              cy$.apply(@, arguments)

      it "sets error command state", (done) ->
        @Cypress.on "log", (@log) =>

        @cy.on "fail", (err) =>
          expect(@log.get("state")).to.eq "error"
          expect(@log.get("error")).to.eq err
          done()

        @failVisit()

        @cy.visit("index.html")

      it "logs once on error", (done) ->
        logs = []

        @Cypress.on "log", (log) ->
          logs.push log

        @failVisit()

        @cy.on "fail", (err) ->
          expect(logs).to.have.length(1)
          done()

        @cy.visit("index.html")

      it "throws when url isnt a string", (done) ->
        @cy.on "fail", (err) ->
          expect(err.message).to.eq "cy.visit() must be called with a string as its 1st argument"
          done()

        @cy.visit()

      it "throws when visit times out", (done) ->
        @cy.on "fail", (err) ->
          expect(err.message).to.eq "Timed out after waiting '500ms' for your remote page to load."
          done()

        @cy.visit("timeout?ms=5000", {timeout: 500})

      it "unbinds remoteIframe load event"

      it "only logs once on error", (done) ->
        logs = []

        @Cypress.on "log", (@log) =>
          logs.push @log

        @cy.on "fail", (err) =>
          expect(logs.length).to.eq(1)
          expect(@log.get("error")).to.eq(err)
          done()

        @cy.visit("timeout?ms=5000", {timeout: 500})

  context "#loading", ->
    it "clears current timeout"

    describe ".log", ->
      beforeEach ->
        @Cypress.on "log", (@log) =>

      it "returns if current command is visit", ->
        logs = []

        @Cypress.on "log", (log) ->
          logs.push log

        cy.visit("/fixtures/html/sinon.html").then ->
          expect(logs).to.have.length(1)

      it "is name: loading", ->
        cy.get("form#click-me").find("input").click().then ->
          expect(@log.get("name")).to.eq "loading"

      it "is type: parent", ->
        cy.get("form#click-me").submit().then ->
          expect(@log.get("type")).to.eq "parent"

      describe "#onConsole", ->
        it "only has Command: loading", ->
          cy.get("form#click-me").submit().then ->
            expect(@log.attributes.onConsole()).to.deep.eq {
              Command: "loading"
            }

    describe "errors", ->
      beforeEach ->
        @allowErrors()

      it "can time out", (done) ->
        logs = []

        @Cypress.on "log", (log) ->
          logs.push log

        @cy.on "fail", (err) ->
          ## should only log once
          expect(logs.length).to.eq 1
          expect(err.message).to.eq "Timed out after waiting '100ms' for your remote page to load."
          done()

        @cy.on "invoke:end", =>
          @cy.isReady(false, "testing")
          @cy.loading({timeout: 100})

        @cy.noop({})

      ## this goes through the same process as visit
      ## where it errors if cypress sent back an error
      it "errors if [cypress-error] was found", (done) ->
        cy$ = @cy.$

        logs = []

        @Cypress.on "log", (log) ->
          logs.push log

        @cy.on "fail", (err) ->
          ## should only log once
          expect(logs.length).to.eq 1
          expect(err.message).to.eq "Loading the new page failed."
          done()

        ## act as if we have this node
        error = @sandbox.stub @cy, "$", (selector) ->
          if selector is "[data-cypress-visit-error]"
            error.restore()
            return {length: 1}
          else
            cy$.apply(@, arguments)

        @cy.on "invoke:end", =>
          @cy.isReady(false, "testing")
          @cy.loading()
          @cy.isReady()

        @cy.noop({})