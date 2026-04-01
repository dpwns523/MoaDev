from typing import Literal

from pydantic import BaseModel, Field, ValidationInfo, field_validator


class FeedItem(BaseModel):
    id: str = Field(min_length=1)
    kind: Literal["news", "pull-request"]
    title: str = Field(min_length=1)
    source: str = Field(min_length=1)

    @field_validator("id", "title", "source")
    @classmethod
    def validate_non_blank_string(cls, value: str, info: ValidationInfo) -> str:
        if not value.strip():
            raise ValueError(f"{info.field_name} must be a non-empty string")
        return value


class FeedResponse(BaseModel):
    data: list[FeedItem]
    meta: dict[str, int]
