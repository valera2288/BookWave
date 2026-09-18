import SimpleCrudList from "../../shared/SimpleCrudList";
import { createAuthor, deleteAuthor, fetchAuthors, renameAuthor } from "./api";

export default function AuthorsPage() {
  return (
    <SimpleCrudList
      title="Авторы"
      fetchItems={fetchAuthors}
      createItem={createAuthor}
      renameItem={renameAuthor}
      deleteItem={deleteAuthor}
    />
  );
}
