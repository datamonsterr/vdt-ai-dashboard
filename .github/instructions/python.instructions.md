---
applyTo: libs/python-lib/**/*
---

# Purpose
Lightweight Python SDK for AI/ML engineers to send metrics and monitoring data to VDT AI platform via Kafka.

# Tech Stack
- **Language**: Python 3.8+ (support up to 3.11)
- **Message Broker**: Kafka (kafka-python)
- **Validation**: Pydantic
- **Logging**: Loguru
- **Serialization**: Protobuf
- **CLI**: Click
- **Testing**: pytest with coverage

# Package Structure
```
src/vdt_ai/
├── client.py           # Main SDK client
├── models.py           # Pydantic models
├── kafka/              # Kafka producer
├── proto/              # Generated protobuf
├── integrations/       # Framework integrations (Spark, sklearn)
└── cli.py              # Command-line interface
```

# Coding Style
1. **Standards**: PEP 8 compliance, strict type hints
2. **Tools**: black (88 chars), isort, flake8, mypy
3. **Naming**: 
   - Classes: `PascalCase` 
   - Functions: `snake_case`
   - Constants: `UPPER_SNAKE_CASE`
   - Private: `_underscore_prefix`

# API Design
```python
# Simple, intuitive interface
from vdt_ai import VDTClient

client = VDTClient(api_key="your-api-key")

# Log model calls
client.log_model_call(
    model_name="recommendation_model",
    input_data={"user_id": 123},
    prediction={"items": [1, 2, 3]},
    latency_ms=45
)

# Log data quality
client.log_data_quality(
    dataset_name="user_features",
    record_count=10000,
    null_count=15,
    anomaly_score=0.02
)
```

# Key Requirements
1. **Error Handling**: Custom exceptions, retry mechanisms, structured logging
2. **Async Operations**: Use asyncio for Kafka, connection pooling
3. **Data Models**: Pydantic validation, protobuf compatibility
4. **Configuration**: Environment variables, config files, sensible defaults
5. **Security**: Never log sensitive data, API key validation

# Framework Integrations
1. **Apache Spark**: Decorators for job monitoring
2. **ML Frameworks**: scikit-learn, TensorFlow, PyTorch support
3. **Optional Dependencies**: Use extras_require for integrations

# Testing & Quality
1. **Coverage**: >90% test coverage required
2. **Tests**: Unit tests, integration tests with Kafka mocks
3. **Documentation**: Google-style docstrings, usage examples
4. **Performance**: Memory management, bulk operations

# Development
1. **Environment**: Use virtual environments, `pip install -e .`
2. **Quality Checks**: Run black, isort, flake8, mypy before commits
3. **CLI Tools**: 
   ```bash
   vdt-ai configure --api-key YOUR_KEY
   vdt-ai test-connection
   vdt-ai validate-config
   ```

# Deployment
1. **Package**: setup.py with semantic versioning
2. **Dependencies**: Pin major versions, minimize required deps
3. **Distribution**: PyPI publication with proper versioning
