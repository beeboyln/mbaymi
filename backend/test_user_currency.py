from app.models.user import User


def test_user_model_has_currency_field():
    assert 'currency' in User.__table__.columns.keys()
