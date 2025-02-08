const Koa = require("koa");
const app = (module.exports = new Koa());
const server = require("http").createServer(app.callback());
const WebSocket = require("ws");
const wss = new WebSocket.Server({ server });
const Router = require("koa-router");
const cors = require("@koa/cors");
const bodyParser = require("koa-bodyparser");

app.use(bodyParser());
app.use(cors());
app.use(middleware);

function middleware(ctx, next) {
  const start = new Date();
  return next().then(() => {
    const ms = new Date() - start;
    console.log(
      `${start.toLocaleTimeString()} ${ctx.response.status} ${
        ctx.request.method
      } ${ctx.request.url} - ${ms}ms`
    );
  });
}

const jobs = [
  {
    id: 1,
    title: "Software Engineer",
    company: "TechCorp",
    description: "Develop and maintain software applications.",
    status: "open",
    applicants: 5,
    location: "Remote",
  },
  {
    id: 2,
    title: "Data Scientist",
    company: "DataX",
    description: "Analyze large datasets to derive insights.",
    status: "open",
    applicants: 8,
    location: "New York",
  },
  {
    id: 3,
    title: "Product Manager",
    company: "Innovate Ltd.",
    description: "Lead product development initiatives.",
    status: "open",
    applicants: 3,
    location: "San Francisco",
  },
  {
    id: 4,
    title: "Graphic Designer",
    company: "Creative Studio",
    description: "Design digital and print assets.",
    status: "closed",
    applicants: 2,
    location: "Los Angeles",
  },
  {
    id: 5,
    title: "Marketing Specialist",
    company: "AdGrow",
    description: "Plan and execute marketing campaigns.",
    status: "open",
    applicants: 6,
    location: "Chicago",
  },
  {
    id: 6,
    title: "Cybersecurity Analyst",
    company: "SecureIT",
    description: "Ensure security of IT infrastructure.",
    status: "open",
    applicants: 7,
    location: "Washington D.C.",
  },
  {
    id: 7,
    title: "HR Manager",
    company: "PeopleFirst",
    description: "Manage recruitment and employee relations.",
    status: "open",
    applicants: 4,
    location: "Austin",
  },
  {
    id: 8,
    title: "Frontend Developer",
    company: "WebWorks",
    description: "Build user-friendly web applications.",
    status: "open",
    applicants: 9,
    location: "Remote",
  },
  {
    id: 9,
    title: "Business Analyst",
    company: "BizAnalytics",
    description: "Analyze business processes and improve efficiency.",
    status: "open",
    applicants: 5,
    location: "Boston",
  },
  {
    id: 10,
    title: "Customer Support Representative",
    company: "HelpDesk",
    description: "Assist customers with inquiries and issues.",
    status: "open",
    applicants: 12,
    location: "Remote",
  },
];

const router = new Router();

router.get("/jobs", (ctx) => {
  ctx.response.body = jobs;
  ctx.response.status = 200;
});

router.get("/allJobs", (ctx) => {
  ctx.response.body = jobs;
  ctx.response.status = 200;
});

router.get("/job/:id", (ctx) => {
  const { id } = ctx.params;
  const job = jobs.find((j) => j.id == id);
  if (job) {
    ctx.response.body = job;
    ctx.response.status = 200;
  } else {
    ctx.response.body = { error: `Job with id ${id} not found` };
    ctx.response.status = 404;
  }
});

router.post("/job", (ctx) => {
  const { title, company, description, status, applicants, location } =
    ctx.request.body;

  if (title && company && description && status && applicants && location) {
    const id = jobs.length > 0 ? Math.max(...jobs.map((j) => j.id)) + 1 : 1;
    const newJob = {
      id,
      title,
      company,
      description,
      status,
      applicants,
      location,
    };
    jobs.push(newJob);

    broadcast(newJob);
    ctx.response.body = newJob;
    ctx.response.status = 201;
  } else {
    const errorMessage = `Missing or invalid fields title: ${title}, 
       company: ${company}, description: ${description}, status: ${status}, 
       applicants: ${applicants}, location: ${location}`;
    console.log(errorMessage);
    ctx.response.body = { error: errorMessage };
    ctx.response.status = 400;
  }
});

router.delete("/job/:id", (ctx) => {
  const { id } = ctx.params;
  const index = jobs.findIndex((j) => j.id == id);
  if (index !== -1) {
    const deletedJob = jobs.splice(index, 1)[0];
    ctx.response.body = deletedJob;
    ctx.response.status = 200;
  } else {
    ctx.response.body = { error: `Job with id ${id} not found` };
    ctx.response.status = 404;
  }
});

const broadcast = (data) => {
  wss.clients.forEach((client) => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(JSON.stringify(data));
    }
  });
};

// Register routes
app.use(router.routes());
app.use(router.allowedMethods());

const port = 2506;
server.listen(port, () => {
  console.log(`Server running on port ${port}... 🚀`);
});
