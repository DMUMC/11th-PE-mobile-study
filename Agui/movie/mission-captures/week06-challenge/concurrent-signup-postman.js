// Challenge Mission: real concurrent POST requests to the local server.
// The parent GET only triggers this After response script.
const tag = String(Date.now()).slice(-7);
const count = 8;
pm.test("Probe request: 200", () => pm.response.to.have.status(200));
function runBatch(label, expectedCode, makeBody, done) {
  const results = [];
  for (let i = 0; i < count; i++) {
    pm.sendRequest({
      url: "http://localhost:8080/members",
      method: "POST",
      header: { "Content-Type": "application/json" },
      body: { mode: "raw", raw: JSON.stringify(makeBody(i)) }
    }, (error, response) => {
      pm.test(label + " #" + (i + 1) + ": 201 or 409 / " + expectedCode, () => {
        pm.expect(error).to.equal(null);
        pm.expect([201, 409]).to.include(response.code);
        const body = response.json();
        if (response.code === 409) {
          pm.expect(body.isSuccess).to.equal(false);
          pm.expect(body.code).to.equal(expectedCode);
          pm.expect(body.result).to.equal(null);
          pm.expect(body.message).to.equal(label === "EMAIL" ? "이미 사용 중인 이메일입니다." : "이미 사용 중인 닉네임입니다.");
        } else {
          pm.expect(body.isSuccess).to.equal(true);
          pm.expect(body.result).not.to.have.property("password");
        }
      });
      results.push({status: error ? 0 : response.code, body: error ? String(error) : response.json()});
      if (results.length === count) {
        const created = results.filter(r => r.status === 201).length;
        const conflicts = results.filter(r => r.status === 409).length;
        pm.test(label + " concurrent x8: 201=" + created + ", 409=" + conflicts + " / tag=" + tag, () => {
          pm.expect(created).to.equal(1);
          pm.expect(conflicts).to.equal(7);
        });
        console.log("CHALLENGE_RACE", label, tag, JSON.stringify(results));
        if (done) done();
      }
    });
  }
}
runBatch("EMAIL", "MEMBER4091", i => ({
  email: "race-email-" + tag + "@example.com",
  password: "Umc!1234",
  nickname: "E" + tag + i
}), () => runBatch("NICKNAME", "MEMBER4092", i => ({
  email: "race-nick-" + tag + "-" + i + "@example.com",
  password: "Umc!1234",
  nickname: "N" + tag
})));
