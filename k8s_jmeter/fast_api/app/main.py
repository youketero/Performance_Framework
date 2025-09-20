import os
import time
from datetime import datetime, timedelta
from typing import List, Optional
import jwt
import logging
from fastapi import FastAPI, HTTPException, Depends, Header
from pydantic import BaseModel
import requests

# ------------------ LOGGING ------------------
LOG_DIR = "/logs"
os.makedirs(LOG_DIR, exist_ok=True)

logger = logging.getLogger("fastapi_app")
logger.setLevel(logging.INFO)

formatter = logging.Formatter("%(asctime)s - %(levelname)s - %(message)s")

file_handler = logging.FileHandler(os.path.join(LOG_DIR, "app.log"))
file_handler.setFormatter(formatter)
logger.addHandler(file_handler)

console_handler = logging.StreamHandler()
console_handler.setFormatter(formatter)
logger.addHandler(console_handler)

# ------------------ FASTAPI APP ------------------
app = FastAPI(title="Sample FastAPI App")

SECRET_KEY = "mocksecret"
ALGORITHM = "HS256"
USE_MOCK = os.getenv("USE_MOCK", "true").lower() == "true"

# ------------------ MODELS ------------------
class Rating(BaseModel):
    rate: float
    count: int

class Product(BaseModel):
    id: Optional[int] = None
    title: str
    price: float
    description: str
    category: str
    image: str
    rating: Rating

class Geolocation(BaseModel):
    lat: str
    long: str

class Address(BaseModel):
    geolocation: Geolocation
    city: str
    street: str
    number: int
    zipcode: str

class Name(BaseModel):
    firstname: str
    lastname: str

class User(BaseModel):
    id: int
    email: str
    username: str
    password: str
    name: Name
    phone: str
    address: Address
    __v: int

class LoginRequest(BaseModel):
    username: str
    password: str

class LoginResponse(BaseModel):
    token: str

class CartItem(BaseModel):
    productId: int
    quantity: int

class Cart(BaseModel):
    id: Optional[int] = None
    userId: int
    date: datetime
    products: List[CartItem]

# ------------------ FAKE DATA ------------------
fake_products = [
    Product(
        id=1,
        title="Fjallraven - Foldsack No. 1 Backpack, Fits 15 Laptops",
        price=109.95,
        description="Your perfect pack for everyday use and walks in the forest.",
        category="men's clothing",
        image="https://fakestoreapi.com/img/81fPKd-2AYL._AC_SL1500_t.png",
        rating=Rating(rate=3.9, count=120)
    ),
    Product(
        id=2,
        title="Mens Casual Premium Slim Fit T-Shirts",
        price=22.3,
        description="Slim-fitting style, contrast raglan long sleeve...",
        category="men's clothing",
        image="https://fakestoreapi.com/img/71-3HjGNDUL._AC_SY879._SX._UX._SY._UY_t.png",
        rating=Rating(rate=4.1, count=259)
    )
]

fake_users = [
    User(
        id=1,
        email="john@gmail.com",
        username="johnd",
        password="m38rmF$",
        name=Name(firstname="john", lastname="doe"),
        phone="1-570-236-7033",
        address=Address(
            geolocation=Geolocation(lat="-37.3159", long="81.1496"),
            city="kilcoole",
            street="new road",
            number=7682,
            zipcode="12926-3874"
        ),
        __v=0
    )
]

fake_carts = [
    Cart(
        id=1,
        userId=1,
        date=datetime.strptime("2020-03-02", "%Y-%m-%d"),
        products=[CartItem(productId=1, quantity=2), CartItem(productId=2, quantity=1)]
    )
]

# ------------------ HELPERS ------------------
def get_current_user(authorization: str = Header(...)):
    logger.info(f"Authorization header received: {authorization[:10]}...")
    if not authorization.startswith("Bearer "):
        logger.warning("Invalid token format")
        raise HTTPException(status_code=401, detail="Invalid token")
    token = authorization.split(" ")[1]
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        logger.info(f"Token decoded for user: {payload['sub']}")
        return payload["sub"]
    except jwt.ExpiredSignatureError:
        logger.warning("Token expired")
        raise HTTPException(status_code=401, detail="Token expired")
    except jwt.InvalidTokenError:
        logger.warning("Invalid token")
        raise HTTPException(status_code=401, detail="Invalid token")

@app.post("/reset_mock")
def reset_mock():
    fake_products.clear()
    fake_users.clear()
    fake_carts.clear()
    logger.info("Mock data reset")
    return {"detail": "Mock data reset"}

def generate_mock_jwt(username: str) -> str:
    payload = {
        "sub": username,
        "iat": datetime.utcnow(),
        "exp": datetime.utcnow() + timedelta(hours=1)
    }
    token = jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)
    logger.info(f"Generated JWT for user: {username}")
    return token

def serialize_datetime(obj):
    if isinstance(obj, dict):
        return {k: serialize_datetime(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [serialize_datetime(v) for v in obj]
    elif isinstance(obj, datetime):
        return obj.isoformat()
    return obj

def fetch_from_fakestore(endpoint: str):
    logger.info(f"Fetching from fakestore endpoint: {endpoint}")
    resp = requests.get(f"https://fakestoreapi.com/{endpoint}")
    resp.raise_for_status()
    return resp.json()

def post_to_fakestore(endpoint: str, payload: dict):
    payload_serialized = serialize_datetime(payload)
    logger.info(f"POST to fakestore endpoint: {endpoint} with payload: {payload_serialized}")
    resp = requests.post(f"https://fakestoreapi.com/{endpoint}", json=payload_serialized)
    resp.raise_for_status()
    return resp.json()

def put_to_fakestore(endpoint: str, payload: dict):
    payload_serialized = serialize_datetime(payload)
    logger.info(f"PUT to fakestore endpoint: {endpoint} with payload: {payload_serialized}")
    resp = requests.put(f"https://fakestoreapi.com/{endpoint}", json=payload_serialized)
    resp.raise_for_status()
    return resp.json()

def delete_from_fakestore(endpoint: str):
    logger.info(f"DELETE to fakestore endpoint: {endpoint}")
    resp = requests.delete(f"https://fakestoreapi.com/{endpoint}")
    if resp.status_code == 404:
        raise HTTPException(status_code=404, detail="Not found")
    resp.raise_for_status()
    return {"detail": "Deleted"}

# ------------------ ROUTES ------------------
@app.get("/")
def read_root():
    logger.info("Endpoint / called")
    return {"message": "Hello, FastAPI!"}

@app.get("/wait/{seconds}")
def wait(seconds: int):
    logger.info(f"Endpoint /wait/{seconds} called")
    time.sleep(seconds)
    return {"waited": seconds}

# Products
@app.get("/products", response_model=List[Product])
def get_products():
    logger.info("Endpoint /products GET called")
    return fake_products if USE_MOCK else fetch_from_fakestore("products")

@app.get("/products/{product_id}", response_model=Product)
def get_product(product_id: int):
    logger.info(f"Endpoint /products/{product_id} GET called")
    if USE_MOCK:
        product = next((p for p in fake_products if p.id == product_id), None)
        if not product:
            logger.warning(f"Product {product_id} not found")
            raise HTTPException(status_code=404, detail="Product not found")
        return product
    return fetch_from_fakestore(f"products/{product_id}")

@app.post("/products", response_model=Product, status_code=201)
def create_product(product: Product, username: str = Depends(get_current_user)):
    logger.info(f"Endpoint /products POST called by {username}")
    if USE_MOCK:
        product.id = max([p.id for p in fake_products], default=0) + 1
        fake_products.append(product)
        logger.info(f"Product created: {product.dict()}")
        return product
    return post_to_fakestore("products", product.dict())

@app.put("/products/{product_id}", response_model=Product)
def update_product(product_id: int, product: Product):
    logger.info(f"Endpoint /products/{product_id} PUT called")
    if USE_MOCK:
        idx = next((i for i, p in enumerate(fake_products) if p.id == product_id), None)
        if idx is None:
            logger.warning(f"Product {product_id} not found for update")
            raise HTTPException(status_code=404, detail="Product not found")
        fake_products[idx] = product
        logger.info(f"Product updated: {product.dict()}")
        return product
    return put_to_fakestore(f"products/{product_id}", product.dict())

@app.delete("/products/{product_id}", status_code=204)
def delete_product(product_id: int):
    logger.info(f"Endpoint /products/{product_id} DELETE called")
    if USE_MOCK:
        idx = next((i for i, p in enumerate(fake_products) if p.id == product_id), None)
        if idx is None:
            logger.warning(f"Product {product_id} not found for deletion")
            raise HTTPException(status_code=404, detail="Product not found")
        fake_products.pop(idx)
        logger.info(f"Product {product_id} deleted")
        return
    return delete_from_fakestore(f"products/{product_id}")

# Users
@app.get("/users", response_model=List[User])
def get_users():
    logger.info("Endpoint /users GET called")
    return fake_users if USE_MOCK else fetch_from_fakestore("users")

@app.get("/users/{user_id}", response_model=User)
def get_user(user_id: int):
    logger.info(f"Endpoint /users/{user_id} GET called")
    if USE_MOCK:
        user = next((u for u in fake_users if u.id == user_id), None)
        if not user:
            logger.warning(f"User {user_id} not found")
            raise HTTPException(status_code=404, detail="User not found")
        return user
    return fetch_from_fakestore(f"users/{user_id}")

@app.post("/users", response_model=User, status_code=201)
def create_user(user: User):
    logger.info(f"Endpoint /users POST called")
    if USE_MOCK:
        user.id = max((u.id for u in fake_users), default=0) + 1
        fake_users.append(user)
        logger.info(f"User created: {user.dict()}")
        return user
    return post_to_fakestore("users", user.dict())

@app.put("/users/{user_id}", response_model=User)
def update_user(user_id: int, user: User):
    logger.info(f"Endpoint /users/{user_id} PUT called")
    if USE_MOCK:
        idx = next((i for i, u in enumerate(fake_users) if u.id == user_id), None)
        if idx is None:
            logger.warning(f"User {user_id} not found for update")
            raise HTTPException(status_code=404, detail="User not found")
        fake_users[idx] = user
        logger.info(f"User updated: {user.dict()}")
        return user
    return put_to_fakestore(f"users/{user_id}", user.dict())

@app.delete("/users/{user_id}", status_code=204)
def delete_user(user_id: int):
    logger.info(f"Endpoint /users/{user_id} DELETE called")
    if USE_MOCK:
        idx = next((i for i, u in enumerate(fake_users) if u.id == user_id), None)
        if idx is None:
            logger.warning(f"User {user_id} not found for deletion")
            raise HTTPException(status_code=404, detail="User not found")
        fake_users.pop(idx)
        logger.info(f"User {user_id} deleted")
        return
    return delete_from_fakestore(f"users/{user_id}")

# Login
@app.post("/login", response_model=LoginResponse)
def login_user(login: LoginRequest):
    logger.info(f"Endpoint /login called for username: {login.username}")
    if USE_MOCK:
        user = next((u for u in fake_users if u.username == login.username), None)
        if not user or user.password != login.password:
            logger.warning(f"Invalid login attempt for username: {login.username}")
            raise HTTPException(status_code=401, detail="Invalid username or password")
        token = generate_mock_jwt(user.username)
        return {"token": token}
    resp = requests.post(
        "https://fakestoreapi.com/auth/login",
        json={"username": login.username, "password": login.password}
    )
    resp.raise_for_status()
    return {"token": resp.json().get("token")}

# Carts
@app.get("/carts", response_model=List[Cart])
def get_carts():
    logger.info("Endpoint /carts GET called")
    return fake_carts if USE_MOCK else fetch_from_fakestore("carts")

@app.get("/carts/{cart_id}", response_model=Cart)
def get_cart(cart_id: int):
    logger.info(f"Endpoint /carts/{cart_id} GET called")
    if USE_MOCK:
        cart = next((c for c in fake_carts if c.id == cart_id), None)
        if not cart:
            logger.warning(f"Cart {cart_id} not found")
            raise HTTPException(status_code=404, detail="Cart not found")
        return cart
    return fetch_from_fakestore(f"carts/{cart_id}")

@app.post("/carts", response_model=Cart, status_code=201)
def create_cart(cart: Cart, username: str = Depends(get_current_user)):
    logger.info(f"Endpoint /carts POST called by {username}")
    if USE_MOCK:
        cart.id = max([c.id for c in fake_carts], default=0) + 1
        cart.userId = next((u.id for u in fake_users if u.username == username), cart.userId)
        fake_carts.append(cart)
        logger.info(f"Cart created: {cart.dict()}")
        return cart
    return post_to_fakestore("carts", cart.dict())

@app.put("/carts/{cart_id}", response_model=Cart)
def update_cart(cart_id: int, cart: Cart):
    logger.info(f"Endpoint /carts/{cart_id} PUT called")
    if USE_MOCK:
        idx = next((i for i, c in enumerate(fake_carts) if c.id == cart_id), None)
        if idx is None:
            logger.warning(f"Cart {cart_id} not found for update")
            raise HTTPException(status_code=404, detail="Cart not found")
        fake_carts[idx] = cart
        logger.info(f"Cart updated: {cart.dict()}")
        return cart
    return put_to_fakestore(f"carts/{cart_id}", cart.dict())

@app.delete("/carts/{cart_id}", status_code=204)
def delete_cart(cart_id: int):
    logger.info(f"Endpoint /carts/{cart_id} DELETE called")
    if USE_MOCK:
        idx = next((i for i, c in enumerate(fake_carts) if c.id == cart_id), None)
        if idx is None:
            logger.warning(f"Cart {cart_id} not found for deletion")
            raise HTTPException(status_code=404, detail="Cart not found")
        fake_carts.pop(idx)
        logger.info(f"Cart {cart_id} deleted")
        return
    return delete_from_fakestore(f"carts/{cart_id}")
