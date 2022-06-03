import http, { options } from 'k6/http'
import encoding from 'k6/encoding'
import { check, sleep } from 'k6'

const baseurl = __ENV.BASE_URL
const targeturl = __ENV.TARGET_URL
const username = 'bittrance' // __ENV.USERNAME
const password = '7TI2jLOtKMrgY6CSNWcn' // __ENV.PASSWORD
const credentials = encoding.b64encode(`${username}:${password}`)
const params = {
    auth: 'basic',
    headers: {
        Authorization: `Basic ${credentials}`,
        'Content-Type': 'application/json',
    },
}

let iterations = 0

function make_job(name) {
    return JSON.stringify({
        name: name,
        schedule: '@every 2s',
        executor: 'http',
        executor_config: {
            method: 'PUT',
            url: `${targeturl}/log/${name}`,
            timeout: '10',
            expectCode: '200',
            expectBody: 'ok'
        }
    })
}

export function setup() {
    let r = http.del(`${targeturl}/logs`)
    check(r, {
        'status is 200': (r) => r.status == 200,
    })
    console.log(r.body)
}

export default function () {
    let job = make_job(`job-${__ITER}`)
    let r = http.post(`${baseurl}/v1/jobs`, job, params)
    check(r, {
        'status is 201': (r) => r.status === 201,
    })
    iterations += 1
}

export function teardown() {
    sleep(1)
    let r = http.get(`${targeturl}/logs`)
    check(r, {
        'status is 200': (r) =>
            r.status == 200,
        'all crons have called in': (r) =>
            Object.keys(JSON.parse(r.body)).length == iterations,
    })
    r = http.del(`${targeturl}/logs`)
    check(r, {
        'status is 200': (r) => r.status == 200,
    })
}