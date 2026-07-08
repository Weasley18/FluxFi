# FluxFi

> **AI-powered financial management platform for small businesses** — built with OpenAI, LangGraph, FastAPI, and React.

[![Python](https://img.shields.io/badge/Python-3.11-blue?logo=python)](https://python.org)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.111-009688?logo=fastapi)](https://fastapi.tiangolo.com)
[![React](https://img.shields.io/badge/React-18-61DAFB?logo=react)](https://react.dev)
[![LangGraph](https://img.shields.io/badge/LangGraph-ReAct_Agent-FF6B35)](https://langchain-ai.github.io/langgraph/)
[![OpenAI](https://img.shields.io/badge/OpenAI-GPT--4o--mini-412991?logo=openai)](https://openai.com)
[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker)](https://docker.com)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-336791?logo=postgresql)](https://postgresql.org)

---

## What It Does

FluxFi turns a bank statement PDF into a full financial intelligence dashboard — no manual data entry, no spreadsheets.

Upload your bank statement → AI extracts every transaction → ask questions in plain English → get forecasts, anomaly alerts, and budget tracking.

---

## Features

| Feature | Tech |
|---|---|
| **Bank PDF Parser** | `pdfplumber` + OpenAI GPT-4o-mini extracts transactions from any bank statement format |
| **Conversational AI** | LangGraph ReAct agent with persistent memory (`MemorySaver`) + OpenAI GPT-4o-mini |
| **Cash Flow Forecast** | Facebook Prophet time-series model, auto-configured based on data availability |
| **Anomaly Detection** | OpenAI GPT-4o-mini identifies duplicate charges, unusual spikes, and suspicious patterns |
| **AI Insights** | OpenAI GPT-4o-mini real-time financial analysis — income trends, expense patterns, recommendations |
| **Budget Goals** | Set monthly category limits, track progress with visual indicators |
| **Invoice Processing** | OCR (`pytesseract` + `pdf2image`) + OpenAI GPT-4o-mini extracts vendor, amount, due date, and line items |
| **Gmail Integration** | Google OAuth2 flow + Celery background workers automatically poll and import invoice attachments |
| **Multi-Currency** | USD, EUR, GBP, INR, AUD, CAD display with conversion |
| **Report Export** | Download transactions as PDF or Excel |
| **Scheduled Reports** | Monthly email reports via Celery beat + SMTP |

---

## Architecture

```
┌─────────────────┐     ┌────────────────────────────────────────┐
│   React (Vite)  │────▶│           FastAPI Backend               │
│   + TailwindCSS │     │                                        │
│   + Chart.js    │     │  ┌──────────────┐  ┌───────────────┐  │
└─────────────────┘     │  │ LangGraph    │  │ PDF Parser    │  │
                        │  │ ReAct Agent  │  │ pdfplumber    │  │
        Nginx           │  │ (3 tools)    │  │ + OpenAI      │  │
      (reverse          │  └──────┬───────┘  └───────────────┘  │
        proxy)          │         │                               │
                        │  ┌──────▼───────┐  ┌───────────────┐  │
                        │  │ OpenAI       │  │ Prophet       │  │
                        │  │ GPT-4o-mini  │  │ Forecasting   │  │
                        │  └──────────────┘  └───────────────┘  │
                        └────────────┬───────────────────────────┘
                                     │
                    ┌────────────────┼────────────────┐
                    ▼                ▼                ▼
              PostgreSQL           Redis           Celery
              (transactions,    (task queue)     (async jobs,
               invoices,                        monthly reports)
               budget goals)
```

---

## AI Stack

### LangGraph ReAct Agent
The chat feature uses a full LangGraph graph with:
- **MemorySaver** checkpointing — conversation history persists per user, per thread
- **3 tools**: `search_transactions` (RAG), `get_financial_summary`, `list_invoices`
- **System prompt** keeps the agent focused on financial context
- Conditional edges: agent decides whether to call tools or respond directly

```python
graph = StateGraph(AgentState)
graph.add_node("agent", call_model)
graph.add_node("tools", ToolNode(TOOLS))
graph.set_entry_point("agent")
graph.add_conditional_edges("agent", tools_condition)
graph.add_edge("tools", "agent")
```

### PDF Transaction Extraction
1. `pdfplumber.extract_tables()` — preserves column structure (Date | Description | Debit | Credit | Balance)
2. Pipe-separated rows sent to OpenAI GPT-4o-mini with explicit parsing rules
3. Fallback to `extract_text()` for digital text extraction
4. MD5 deduplication — re-uploading the same statement never creates duplicate transactions

### Facebook Prophet Forecasting
- Auto-detects yearly seasonality: enabled only when ≥12 months of data exist
- `n_changepoints` scaled to `n_months // 3` to prevent overfitting on sparse data
- Forecasts **net cash flow** (income + expenses) not revenue-only
- Returns empty state gracefully when data is insufficient

---

## Quick Start

### Prerequisites
- Docker + Docker Compose
- OpenAI API key

### Run

```bash
git clone https://github.com/apuroopy1-prog/fluxfi.git
cd fluxfi

cp .env.example .env
# Edit .env — add your OPENAI_API_KEY

docker compose up -d --build
```

Open [http://localhost](http://localhost)

### Default Login
Register a new account on first run.

---

## Project Structure

```
fluxfi/
├── backend/
│   ├── app/
│   │   ├── routers/          # FastAPI route handlers
│   │   │   ├── transactions.py   # Upload PDF/CSV, anomaly detection
│   │   │   ├── chat.py           # LangGraph agent, AI insights
│   │   │   ├── forecast.py       # Prophet forecasting
│   │   │   ├── invoices.py       # Invoice upload + processing
│   │   │   ├── budgets.py        # Budget goals CRUD
│   │   │   └── reports.py        # PDF/Excel export
│   │   ├── services/
│   │   │   ├── langgraph_chat.py     # LangGraph ReAct agent
│   │   │   ├── forecast_service.py   # Facebook Prophet wrapper
│   │   │   ├── rag_service.py        # Vector search for transactions
│   │   │   └── cache_invalidation.py # Cross-service cache management
│   │   ├── models.py         # SQLAlchemy ORM models
│   │   ├── schemas.py        # Pydantic schemas
│   │   └── main.py           # FastAPI app + middleware
│   ├── requirements.txt
│   └── Dockerfile
├── frontend/
│   ├── src/
│   │   ├── pages/            # Dashboard, Transactions, Forecasting, etc.
│   │   ├── contexts/         # AuthContext with JWT handling
│   │   └── services/         # API client (axios)
│   ├── package.json
│   └── Dockerfile
├── nginx/
│   └── nginx.conf
├── docker-compose.yml
└── .env.example
```

---

## Environment Variables

```env
# Database
POSTGRES_USER=accounting
POSTGRES_PASSWORD=your_password
POSTGRES_DB=accountingdb

# Security
SECRET_KEY=your_secret_key_here
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60

# AI
OPENAI_API_KEY=your_openai_api_key_here
```

---

## Tech Stack

| Layer | Technology |
|---|---|
| **AI / LLM** | OpenAI GPT-4o-mini |
| **Agent Framework** | LangGraph (ReAct), LangChain |
| **Forecasting** | Facebook Prophet |
| **PDF & OCR Extraction** | `pdfplumber`, Tesseract OCR (`pytesseract`, `pdf2image`) |
| **Backend** | FastAPI, SQLAlchemy, Pydantic, Celery |
| **Database** | PostgreSQL, Redis |
| **Frontend** | React 18, Vite 5, TailwindCSS 3, Chart.js |
| **Infrastructure** | Docker Compose, Nginx |
| **Auth** | JWT (access + refresh tokens), Google OAuth2 |

---

## Built By

**Apuroop Yarabarla** — AI/ML Engineer & AI Product Owner

[![LinkedIn](https://img.shields.io/badge/LinkedIn-apuroopyarabarla-0077B5?logo=linkedin)](https://linkedin.com/in/apuroopyarabarla)
[![GitHub](https://img.shields.io/badge/GitHub-apuroopy1--prog-181717?logo=github)](https://github.com/apuroopy1-prog)
