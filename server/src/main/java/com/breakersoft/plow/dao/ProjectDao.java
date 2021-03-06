package com.breakersoft.plow.dao;

import java.util.List;
import java.util.UUID;

import com.breakersoft.plow.Folder;
import com.breakersoft.plow.Project;

public interface ProjectDao {

    /**
     *
     * @param name
     * @param title
     * @return
     */
    Project create(String title, String code);

    /**
     *
     * @param name
     * @return
     */
    Project get(String name);

    /**
     * Set the project's default folder. This is where
     * unfiltered jobs go.
     *
     * @param project
     * @param folder
     */
    void setDefaultFolder(Project project, Folder folder);

    /**
     *
     * @param id
     * @return
     */
    Project get(UUID id);

    /**
     * Get all projects.
     *
     * @return
     */
    List<Project> getAll();

    /**
     * Set the project active or inactive.
     *
     * @param project
     * @param active
     */
	void setActive(Project project, boolean active);
}
