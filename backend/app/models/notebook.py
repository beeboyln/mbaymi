from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey, Boolean, JSON
from sqlalchemy.orm import relationship
from app.models.base import Base
from datetime import datetime

class ProjectNotebook(Base):
    __tablename__ = "project_notebooks"
    
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    farm_id = Column(Integer, ForeignKey("farms.id", ondelete="CASCADE"), nullable=True)
    created_by = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    category = Column(String(50), default="general")  # culture, elevage, finance, maintenance
    is_public = Column(Boolean, default=False)
    
    # JSON content for sections and metadata
    sections = Column(JSON, default=[])  # List of NotebookSection objects
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    farm = relationship("Farm", backref="notebooks")
    creator = relationship("User", backref="created_notebooks")
    comments = relationship("NotebookComment", back_populates="notebook", cascade="all, delete-orphan")
    tags = relationship("NotebookTag", back_populates="notebook", cascade="all, delete-orphan")
    shares = relationship("NotebookShare", back_populates="notebook", cascade="all, delete-orphan")
    versions = relationship("NotebookVersion", back_populates="notebook", cascade="all, delete-orphan")


class NotebookSection(Base):
    """Represents a section within a notebook - stored as JSON in sections column"""
    __tablename__ = "notebook_sections"
    
    id = Column(Integer, primary_key=True, index=True)
    notebook_id = Column(Integer, ForeignKey("project_notebooks.id", ondelete="CASCADE"), nullable=False)
    title = Column(String(255), nullable=False)
    order = Column(Integer, default=0)
    
    # JSON content for note contents
    contents = Column(JSON, default=[])  # List of NoteContent objects
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class NotebookTag(Base):
    __tablename__ = "notebook_tags"
    
    id = Column(Integer, primary_key=True, index=True)
    notebook_id = Column(Integer, ForeignKey("project_notebooks.id", ondelete="CASCADE"), nullable=False)
    tag = Column(String(100), nullable=False)
    
    # Relationships
    notebook = relationship("ProjectNotebook", back_populates="tags")


class NotebookComment(Base):
    __tablename__ = "notebook_comments"
    
    id = Column(Integer, primary_key=True, index=True)
    notebook_id = Column(Integer, ForeignKey("project_notebooks.id", ondelete="CASCADE"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    text = Column(Text, nullable=False)
    
    created_at = Column(DateTime, default=datetime.utcnow)
    deleted_at = Column(DateTime, nullable=True)
    
    # Relationships
    notebook = relationship("ProjectNotebook", back_populates="comments")
    user = relationship("User", backref="notebook_comments")


class NotebookShare(Base):
    """Represents sharing a notebook with other users"""
    __tablename__ = "notebook_shares"
    
    id = Column(Integer, primary_key=True, index=True)
    notebook_id = Column(Integer, ForeignKey("project_notebooks.id", ondelete="CASCADE"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    notebook = relationship("ProjectNotebook", back_populates="shares")
    user = relationship("User", backref="shared_notebooks")


class NotebookVersion(Base):
    """Stores version history/snapshots of notebooks"""
    __tablename__ = "notebook_versions"
    
    id = Column(Integer, primary_key=True, index=True)
    notebook_id = Column(Integer, ForeignKey("project_notebooks.id", ondelete="CASCADE"), nullable=False)
    title = Column(String(255), nullable=False)
    change_description = Column(Text)
    created_by = Column(Integer, ForeignKey("users.id"), nullable=False)
    
    # JSON snapshot of sections
    sections_snapshot = Column(JSON)
    
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    notebook = relationship("ProjectNotebook", back_populates="versions")
    creator = relationship("User", backref="created_notebook_versions")
